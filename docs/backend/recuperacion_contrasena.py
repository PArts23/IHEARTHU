"""
Recuperación de contraseña para el backend FastAPI de I HEART.

Endpoints que consume la app Flutter (rama mejoras-autenticacion):
  POST /auth/recuperar     {correo}                                         -> 200 | 404 | 429
  POST /auth/restablecer   {correo, codigo, nueva_contrasena, confirmar_contrasena} -> 200 | 400 | 404
  GET  /restablecer        ?correo=&codigo=   (página puente que abre la app)
  GET  /.well-known/assetlinks.json         (verifica el App Link de Android)

ADAPTAR (marcado con "ADAPTAR" abajo):
  - obtener_sesion_bd, Usuario y hashear_contrasena -> usa los que ya tiene tu backend.
  - Variables de entorno en Cloud Run:
      SMTP_HOST=smtp.gmail.com  SMTP_PUERTO=587
      SMTP_USUARIO=cuenta@gmail.com  SMTP_CONTRASENA=<contraseña de aplicación de Google>
      URL_PUBLICA=https://i-heart-127320450404.europe-west1.run.app
      ANDROID_SHA256=<huella SHA-256 del certificado que firma el APK>

En /auth/register (CP012 y CP013) responda 409 con un detail que mencione "dni" o "correo", por ejemplo:
  "El número de DNI ingresado ya se encuentra registrado en el sistema"
  "El correo electrónico ya se encuentra registrado. Intente con otro o inicie sesión"
y valide la contraseña con contrasena_segura() (CP015).

Registro en main.py:
  from recuperacion_contrasena import enrutador_auth, enrutador_publico
  app.include_router(enrutador_auth)      # prefijo /auth
  app.include_router(enrutador_publico)   # /restablecer y /.well-known
  Base.metadata.create_all(...)           # crea la tabla codigos_recuperacion
"""

import re
import hashlib
import hmac
import os
import secrets
import smtplib
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from html import escape
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.orm import Session

# ADAPTAR: importa tus propios objetos
from database import Base, obtener_sesion_bd  # noqa: E402
from models import Usuario  # noqa: E402  (columnas: id, correo, nombre_completo, contrasena_hash)
from security import hashear_contrasena  # noqa: E402

LONGITUD_MINIMA_CONTRASENA = 8
MINUTOS_VIGENCIA_CODIGO = 15
MAX_INTENTOS = 5
SEGUNDOS_ENTRE_ENVIOS = 60

URL_PUBLICA = os.getenv("URL_PUBLICA", "https://i-heart-127320450404.europe-west1.run.app")
PAQUETE_ANDROID = "com.example.iheart"


class CodigoRecuperacion(Base):
    __tablename__ = "codigos_recuperacion"

    id = Column(Integer, primary_key=True)
    usuario_id = Column(Integer, index=True, nullable=False)
    codigo_hash = Column(String(64), nullable=False)
    expira_en = Column(DateTime(timezone=True), nullable=False)
    creado_en = Column(DateTime(timezone=True), nullable=False)
    intentos = Column(Integer, default=0, nullable=False)
    usado = Column(Integer, default=0, nullable=False)


class SolicitudRecuperacion(BaseModel):
    correo: EmailStr


class SolicitudRestablecer(BaseModel):
    correo: EmailStr
    codigo: str = Field(pattern=r"^\d{6}$")
    nueva_contrasena: str = Field(min_length=LONGITUD_MINIMA_CONTRASENA)
    confirmar_contrasena: str


enrutador_auth = APIRouter(prefix="/auth", tags=["auth"])
enrutador_publico = APIRouter(tags=["enlaces"])


def _ahora() -> datetime:
    return datetime.now(timezone.utc)


def contrasena_segura(valor: str) -> bool:
    """Misma política que la app (CP015). Úsela también en /auth/register."""
    return (
        len(valor) >= LONGITUD_MINIMA_CONTRASENA
        and re.search(r"[A-ZÁÉÍÓÚÑ]", valor) is not None
        and re.search(r"\d", valor) is not None
        and re.search(r"[^A-Za-z0-9ÁÉÍÓÚÑáéíóúñ\s]", valor) is not None
    )


def _utc(fecha: datetime) -> datetime:
    return fecha if fecha.tzinfo else fecha.replace(tzinfo=timezone.utc)


def _hash_codigo(codigo: str) -> str:
    return hashlib.sha256(codigo.encode()).hexdigest()


def _buscar_usuario(bd: Session, correo: str) -> Usuario:
    usuario = bd.query(Usuario).filter(Usuario.correo == correo.strip().lower()).first()
    if usuario is None:
        raise HTTPException(status_code=404, detail="No existe una cuenta registrada con este correo electrónico.")
    return usuario


def _enviar_correo(destino: str, nombre: str, codigo: str, enlace: str) -> None:
    mensaje = EmailMessage()
    mensaje["Subject"] = "I HEART - Código para restablecer su contraseña"
    mensaje["From"] = os.environ["SMTP_USUARIO"]
    mensaje["To"] = destino
    mensaje.set_content(
        f"Hola {nombre},\n\n"
        f"Su código de verificación es: {codigo}\n"
        f"Vence en {MINUTOS_VIGENCIA_CODIGO} minutos.\n\n"
        f"También puede abrir este enlace desde su celular para restablecerla en la app:\n{enlace}\n\n"
        "Si no solicitó este cambio, ignore este correo."
    )
    mensaje.add_alternative(
        f"""<div style="font-family:sans-serif;max-width:420px;margin:auto">
        <h2 style="color:#7B1624">I HEART</h2>
        <p>Hola {escape(nombre)},</p>
        <p>Su código de verificación es:</p>
        <p style="font-size:32px;letter-spacing:8px;font-weight:bold;color:#7B1624">{codigo}</p>
        <p>Vence en {MINUTOS_VIGENCIA_CODIGO} minutos.</p>
        <p><a href="{enlace}" style="background:#7B1624;color:#fff;padding:12px 24px;
           border-radius:32px;text-decoration:none;display:inline-block">Restablecer en la app</a></p>
        <p style="color:#757575;font-size:12px">Abra el enlace desde el celular donde tiene instalada la app.
        Si no solicitó este cambio, ignore este correo.</p></div>""",
        subtype="html",
    )
    with smtplib.SMTP(os.getenv("SMTP_HOST", "smtp.gmail.com"), int(os.getenv("SMTP_PUERTO", "587"))) as smtp:
        smtp.starttls()
        smtp.login(os.environ["SMTP_USUARIO"], os.environ["SMTP_CONTRASENA"])
        smtp.send_message(mensaje)


@enrutador_auth.post("/recuperar")
def solicitar_recuperacion(datos: SolicitudRecuperacion, bd: Session = Depends(obtener_sesion_bd)):
    usuario = _buscar_usuario(bd, datos.correo)

    ultimo = (
        bd.query(CodigoRecuperacion)
        .filter(CodigoRecuperacion.usuario_id == usuario.id)
        .order_by(CodigoRecuperacion.creado_en.desc())
        .first()
    )
    if ultimo and (_ahora() - _utc(ultimo.creado_en)).total_seconds() < SEGUNDOS_ENTRE_ENVIOS:
        raise HTTPException(status_code=429, detail="Por favor espere 60 segundos antes de solicitar otro código")

    bd.query(CodigoRecuperacion).filter(
        CodigoRecuperacion.usuario_id == usuario.id, CodigoRecuperacion.usado == 0
    ).update({"usado": 1})

    codigo = f"{secrets.randbelow(1_000_000):06d}"
    bd.add(
        CodigoRecuperacion(
            usuario_id=usuario.id,
            codigo_hash=_hash_codigo(codigo),
            creado_en=_ahora(),
            expira_en=_ahora() + timedelta(minutes=MINUTOS_VIGENCIA_CODIGO),
        )
    )
    bd.commit()

    enlace = f"{URL_PUBLICA}/restablecer?{urlencode({'correo': usuario.correo, 'codigo': codigo})}"
    try:
        _enviar_correo(usuario.correo, usuario.nombre_completo, codigo, enlace)
    except Exception as error:
        raise HTTPException(status_code=500, detail="No se pudo enviar el correo.") from error

    return {"mensaje": "Código de verificación enviado."}


@enrutador_auth.post("/restablecer")
def restablecer_contrasena(datos: SolicitudRestablecer, bd: Session = Depends(obtener_sesion_bd)):
    if datos.nueva_contrasena != datos.confirmar_contrasena:
        raise HTTPException(status_code=400, detail="Las contraseñas no coinciden. Por favor verifique")
    if not contrasena_segura(datos.nueva_contrasena):
        raise HTTPException(
            status_code=400,
            detail="La contraseña debe tener al menos 8 caracteres, incluir números, mayúsculas y un carácter especial",
        )

    usuario = _buscar_usuario(bd, datos.correo)
    registro = (
        bd.query(CodigoRecuperacion)
        .filter(CodigoRecuperacion.usuario_id == usuario.id, CodigoRecuperacion.usado == 0)
        .order_by(CodigoRecuperacion.creado_en.desc())
        .first()
    )
    if registro is None or _utc(registro.expira_en) < _ahora():
        raise HTTPException(status_code=400, detail="El código expiró. Solicite uno nuevo.")
    if registro.intentos >= MAX_INTENTOS:
        raise HTTPException(status_code=400, detail="Demasiados intentos. Solicite un nuevo código.")

    if not hmac.compare_digest(registro.codigo_hash, _hash_codigo(datos.codigo)):
        registro.intentos += 1
        bd.commit()
        raise HTTPException(status_code=400, detail="El código de verificación es incorrecto.")

    usuario.contrasena_hash = hashear_contrasena(datos.nueva_contrasena)
    registro.usado = 1
    bd.commit()
    return {"mensaje": "Contraseña actualizada."}


@enrutador_publico.get("/restablecer", response_class=HTMLResponse)
def pagina_puente(correo: str = "", codigo: str = ""):
    consulta = urlencode({"correo": correo, "codigo": codigo})
    enlace_app = f"iheart://app/restablecer?{consulta}"
    enlace_intent = (
        f"intent://app/restablecer?{consulta}#Intent;scheme=iheart;package={PAQUETE_ANDROID};end"
    )
    return f"""<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>I HEART</title></head>
<body style="font-family:sans-serif;text-align:center;padding:48px 24px">
<h2 style="color:#7B1624">I HEART</h2>
<p>Abra la aplicación para restablecer su contraseña.</p>
<p><a href="{escape(enlace_intent)}" style="background:#7B1624;color:#fff;padding:14px 28px;
border-radius:32px;text-decoration:none;display:inline-block">Abrir I HEART</a></p>
<p style="color:#757575;font-size:13px">Si no se abre, ingrese manualmente el código
<b>{escape(codigo)}</b> en la pantalla "Restablecer contraseña" de la app.</p>
<script>setTimeout(function(){{window.location.href={enlace_app!r};}},300);</script>
</body></html>"""


@enrutador_publico.get("/.well-known/assetlinks.json")
def assetlinks():
    huellas = [h.strip() for h in os.getenv("ANDROID_SHA256", "").split(",") if h.strip()]
    return JSONResponse(
        [
            {
                "relation": ["delegate_permission/common.handle_all_urls"],
                "target": {
                    "namespace": "android_app",
                    "package_name": PAQUETE_ANDROID,
                    "sha256_cert_fingerprints": huellas,
                },
            }
        ]
    )
