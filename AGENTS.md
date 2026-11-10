# AGENTS.md — I HEAR(TH) U Flutter App

## Contexto del proyecto

Aplicación móvil Android/iOS para detección temprana de afecciones cardíacas en adultos de Lima Metropolitana. Utiliza Federated Learning para inferencia local y preservación de privacidad. El modelo TFLite se ejecuta en el dispositivo. El backend FastAPI solo gestiona autenticación, distribución del modelo y agregación de pesos.

**Flutter:** 3.41.9 — **Dart:** 3.11.5 — **Target:** Android API 26+ / iOS 14+

---

## Stack técnico obligatorio

```
flutter_secure_storage: ^9.2.2
sqflite: ^2.3.3+1
tflite_flutter: ^0.10.4
http: ^1.2.2
go_router: ^14.2.7
provider: ^6.1.2
fl_chart: ^0.69.0
permission_handler: ^11.3.1
health: ^11.1.0
flutter_blue_plus: ^1.35.3
local_auth: ^2.3.0
```

---

## Estructura del proyecto

```
lib/
  main.dart
  app.dart
  router.dart
  nucleo/
    constantes.dart
    tema.dart
    extensiones.dart
    validadores.dart
    proveedor_estado.dart
  datos/
    base_datos_local.dart
    repositorio_perfil.dart
    repositorio_sesiones.dart
    repositorio_diagnosticos.dart
    repositorio_modelo.dart
    repositorio_dispositivos.dart
    repositorio_preferencias.dart
  red/
    cliente_api.dart
    servicio_auth.dart
    servicio_modelo.dart
    servicio_federado.dart
    servicio_biometrico.dart
    servicio_wearable.dart
    servicio_conectividad.dart
    servicio_dispositivo_local.dart
  reportes/
    generador_reporte_pdf.dart
  modelo/
    inferencia_local.dart
    preprocesamiento.dart
    feature_engineering.dart
    fedavg_local.dart
    generador_recomendaciones.dart
  pantallas/
    auth/
      pantalla_login.dart
      pantalla_registro.dart
      pantalla_recuperar.dart
      pantalla_restablecer.dart
    inicio/
      pantalla_inicio.dart
      vista_panel_principal.dart
    evaluar/
      pantalla_cuestionario.dart
      pantalla_calibracion.dart
      pantalla_resultado.dart
    historial/
      pantalla_historial.dart
      pantalla_diagnostico_detalle.dart
      pantalla_mis_diagnosticos.dart
    perfil/
      pantalla_perfil.dart
    ajustes/
      pantalla_ajustes.dart
      pantalla_iot.dart
      pantalla_health_connect.dart
      pantalla_modelo_fl.dart
  widgets/
    tarjeta_riesgo.dart
    grafico_ppg.dart
    barra_navegacion.dart
    boton_primario.dart
    campo_texto.dart
    tarjeta_sesion.dart
    indicador_carga.dart
    pregunta_opciones.dart
    tabla_comparativa_sesiones.dart
    tarjeta_diagnostico.dart
    tarjeta_ppg_en_vivo.dart
    tarjeta_signo_vital.dart
```

Los textos, mensajes y reglas de validación deben mantenerse alineados con `docs/Casos_de_Prueba_v3.1.xlsx`. La trazabilidad CP → código está en `docs/trazabilidad_casos_prueba.md`; los mensajes viven en `nucleo/constantes.dart` y las reglas en `nucleo/validadores.dart`.

---

## Pantallas y su propósito

### Auth
- **pantalla_login.dart** — Correo + contraseña. Botones: Acceder, Registrar una nueva cuenta, Olvidé mi contraseña. Footer: "Sus datos nunca salen de su dispositivo."
- **pantalla_registro.dart** — Nombre completo, DNI (8 dígitos), correo, contraseña, confirmar contraseña. Footer privacidad.
- **pantalla_recuperar.dart** — Solo campo correo + botón Restablecer + Cancelar.

### Inicio (tab 1)
- Saludo con nombre del paciente y avatar iniciales.
- Tarjeta principal: Riesgo CAD en % + barra degradada 0-100 + badge Normal/CAD.
- Dos tarjetas: Frec. cardíaca (bpm) y SpO2 (%).
- Gráfico de línea: ritmo cardíaco últimas 6 horas.
- Botón CTA primario: INICIAR NUEVO DIAGNÓSTICO.
- BottomNavigationBar 5 tabs: Inicio, Evaluar, Historial, Perfil, Ajustes.

### Evaluar (tab 2)
- **pantalla_calibracion.dart** — Progreso circular (%), texto "¿Qué estamos haciendo?", lista de pasos con íconos, checklist "Configuración inicial".
- **pantalla_cuestionario.dart** — Frecuencia cardíaca registrada + botón registrar nueva. Preguntas clínicas con toggles/selección múltiple (ver sección Datos del cuestionario). Botón COMENZAR DIAGNÓSTICO.
- **pantalla_resultado.dart** — HRV, Avg HR, riesgo, recomendaciones proactivas con íconos. Aviso: "Consulte SIEMPRE a un profesional de la salud."

### Historial (tab 3)
- **pantalla_historial.dart** — Señal PPG en vivo, sesiones recientes con tipo/hora/bpm/estado. Botón EXPORTAR HISTORIAL.
- **pantalla_diagnostico_detalle.dart** — Tabla comparativa penúltima vs última sesión. Datos de cuestionario y riesgo predictivo.

### Perfil (tab 4)
- Avatar con iniciales, nombre, edad, ciudad, badge de nivel de riesgo.
- Campos: nombre, edad, sexo, peso, altura. IMC calculado automáticamente (solo lectura).
- Botón: Actualizar mi perfil.

### Ajustes (tab 5)
- **pantalla_ajustes.dart** — Tarjetas: Mi perfil (editar), Notificaciones (toggle), Dispositivos Vinculados, Revisar modelo federado. Cerrar sesión.
- **pantalla_iot.dart** — Card del dispositivo actual (batería, calidad señal, firmware, procesamiento local). Sección añadir wearable + buscar dispositivos BLE.
- **pantalla_modelo_fl.dart** — Badge "Federated Learning activo", última sincronización. Métricas del modelo: Accuracy, Precisión, Recall, F1-Score. Card del dispositivo conectado con estado PPG.

---

## Datos del cuestionario (variables del modelo)

El formulario de evaluación recopila exactamente las features del modelo ML:

| Variable del modelo   | Elemento UI                                      |
|-----------------------|--------------------------------------------------|
| PR (bpm)              | Lectura automática de IoT o manual               |
| Obesity               | Toggle Sí/No                                     |
| Current Smoker        | Selector: No / Soy fumador activo                |
| EX-Smoker             | Selector: He dejado de fumar                     |
| FH                    | Toggle familiar con CAD prematura Sí/No          |
| DM                    | Checkbox Diabetes en lista enfermedades          |
| HTN                   | Checkbox Hipertensión Arterial                   |
| CVA                   | Checkbox Accidente Cerebrovascular               |
| CRF                   | Checkbox Insuficiencia Renal Crónica             |
| Airway disease        | Checkbox Enfermedad respiratoria crónica         |
| Thyroid Disease       | Checkbox Enfermedad tiroidea                     |
| CHF                   | Checkbox Insuficiencia Cardíaca Congestiva       |
| DLP                   | Checkbox Dislipidemia                            |
| Edema                 | Toggle Sí/No                                     |
| Typical Chest Pain    | Toggle dolor en pecho Sí/No + frecuencia 1-5    |
| Atypical              | Clasificación del dolor (atípico)                |
| Nonanginal            | Clasificación del dolor (no anginoso)            |
| Dyspnea               | Toggle dificultad respiratoria                   |
| Exertional CP         | Toggle esfuerzo físico reciente Sí/No            |

Variables derivadas del perfil (no requieren formulario):
- Age, Weight, Length, Sex, BMI → vienen de `perfil_paciente`

---

## Reglas de código

### Generales
- Sin comentarios en ningún archivo Dart. El código se explica por sí mismo con nombres descriptivos.
- Todas las variables, métodos, clases y archivos en español (excepto nombres de paquetes y palabras clave de Dart/Flutter).
- Sin `print()` en producción. Usar `debugPrint()` solo en modo debug.
- Sin `dynamic` como tipo. Siempre tipar explícitamente.
- Sin `as` para casteos forzados. Usar pattern matching o `is`.
- Toda función asíncrona que pueda fallar usa `try/catch` con manejo explícito del error.
- `const` donde sea posible en widgets y valores.
- Máximo 80 líneas por método. Si supera eso, extraer método.
- Un widget por archivo.

### Estado
- Provider para estado global (autenticación, modelo FL, perfil).
- Estado local con `StatefulWidget` o `ValueNotifier` cuando el estado no necesita ser compartido.
- Sin `setState` en widgets de más de 50 líneas. Extraer a widget hijo.
- Ningún widget accede directamente a la base de datos. Siempre a través del repositorio correspondiente.

### Navegación
- Solo `go_router`. Sin `Navigator.push` directo.
- Rutas definidas únicamente en `router.dart`.
- Rutas protegidas con `redirect` verificando token en `flutter_secure_storage`.

### Red
- Toda comunicación con el backend pasa por `cliente_api.dart`.
- El token JWT se guarda en `flutter_secure_storage`, nunca en `SharedPreferences`.
- Timeout de 30 segundos en todas las peticiones HTTP.
- Manejar explícitamente los códigos 401 (redirigir a login), 409 (mostrar mensaje), 404 y 500.
- Nunca enviar datos médicos del paciente al backend. Solo pesos del modelo.

### Base de datos local
- Toda interacción con SQLite pasa por la clase `BaseDatosLocal` (singleton).
- Usar el schema definido en `ihearth_local.sql` vía `sqflite`.
- Las migraciones se gestionan con `onUpgrade` en `openDatabase`.
- Nunca ejecutar queries crudas fuera de los repositorios.

### Modelo ML
- El archivo `.tflite` se guarda en el directorio de documentos de la app vía `path_provider`.
- `InferenciaLocal` es un singleton inicializado al arranque si existe el modelo.
- El preprocesamiento en `preprocesamiento.dart` replica exactamente el `StandardScaler` del backend (medias y std guardadas como JSON junto al modelo).
- `feature_engineering.dart` replica las 8 variables derivadas del pipeline Python.
- Nunca hacer inferencia si el modelo no está inicializado. Mostrar pantalla de calibración.
- El resultado de inferencia se guarda siempre en `diagnosticos` antes de mostrarse.

### Federated Learning local
- `fedavg_local.dart` gestiona el entrenamiento local sobre las últimas N sesiones del paciente.
- Los pesos se suben a `POST /federated/upload` solo con consentimiento explícito del usuario.
- Los pesos se eliminan del dispositivo tras confirmación de subida exitosa.
- La versión del modelo del servidor se verifica al abrir la app y cada 24 horas.

### Privacidad y seguridad
- Los datos clínicos del paciente (cuestionario, diagnósticos, sesiones) solo existen en SQLite local.
- El backend recibe: credenciales de auth y pesos del modelo (arrays numéricos).
- La biometría (`local_auth`) se puede habilitar opcionalmente como capa adicional al login.
- El token JWT se limpia de `flutter_secure_storage` al cerrar sesión.
- No pedir permisos que no se usen. Permisos mínimos: Bluetooth, Health/HealthConnect, notificaciones.

---

## Diseño visual

### Paleta de colores
```dart
static const Color rojoPrimario    = Color(0xFF7B1624);
static const Color rojoClaro       = Color(0xFFB71C1C);
static const Color blancoFondo     = Color(0xFFFFFFFF);
static const Color grisSuperficie  = Color(0xFFF5F5F5);
static const Color grisBorde       = Color(0xFFE0E0E0);
static const Color textoOscuro     = Color(0xFF1A1A1A);
static const Color textoSecundario = Color(0xFF757575);
static const Color verdeExito      = Color(0xFF2E7D32);
static const Color amarilloAlerta  = Color(0xFFF57C00);
static const Color rojoError       = Color(0xFFD32F2F);
```

### Tipografía
- Fuente del sistema (sans-serif nativa). Sin importar fuentes externas.
- Títulos: `FontWeight.bold`, tamaño 20-24.
- Cuerpo: `FontWeight.normal`, tamaño 14-16.
- Subtítulos y labels: `FontWeight.w600`, tamaño 12-14, color `textoSecundario`.

### Componentes reutilizables obligatorios
- **BotonPrimario** — Fondo `rojoPrimario`, texto blanco, `BorderRadius.circular(32)`, ancho completo, altura 52.
- **BotonSecundario** — Fondo transparente, borde `rojoPrimario`, texto `rojoPrimario`, mismo radio.
- **CampoTexto** — Borde `grisBorde`, radio 12, fondo `grisSuperficie`, sin elevación.
- **TarjetaRiesgo** — Borde redondeado, fondo blanco, sombra sutil, muestra % y badge nivel.
- **GraficoPPG** — `fl_chart` LineChart con color `rojoPrimario`, sin puntos visibles, animado.
- **BarraNavegacion** — 5 ítems, ícono activo en `rojoPrimario`, inactivo en `textoSecundario`.

### Reglas de UI
- `EdgeInsets.symmetric(horizontal: 24)` como padding horizontal estándar.
- Espaciado vertical entre secciones: 24px.
- Cards con `BorderRadius.circular(16)` y `BoxShadow` con opacidad 0.06.
- Sin `Divider` ornamentales. Usar espacio en blanco.
- Sin íconos de Material que no sean estándar. Preferir `Icons.*` del SDK.
- Los estados de carga usan `CircularProgressIndicator` con color `rojoPrimario`.
- Los errores se muestran con `SnackBar` de fondo `rojoError`.
- Las confirmaciones exitosas con `SnackBar` de fondo `verdeExito`.
- Toda pantalla tiene `Scaffold` con `backgroundColor: blancoFondo`.
- El `AppBar` usa `rojoPrimario` como fondo con texto blanco en pantallas de detalle, y blanco con título centrado `rojoPrimario` en tabs principales.

---

## Flujo de la app

```
Inicio frío
  ├── Sin token → PantallaLogin
  │     ├── → PantallaRegistro
  │     └── → PantallaRecuperar
  └── Con token válido → PantallaInicio (tab shell)
        │     INICIAR NUEVO DIAGNÓSTICO: perfil calibrado → Evaluar; si no → PantallaCalibración
        └── PantallaInicio
              ├── Inicio — Dashboard riesgo + métricas + gráfico
              ├── Evaluar → PantallaCuestionario → PantallaResultado
              ├── Historial → PantallaHistorial → PantallaDiagnosticoDetalle
              ├── Perfil → PantallaPerfil
              └── Ajustes → PantallaAjustes
                    ├── → PantallaIoT
                    └── → PantallaModeloFL
```

---

## Integración con el backend

### Endpoints consumidos

| Acción                     | Método | Ruta                   | Auth requerida |
|----------------------------|--------|------------------------|----------------|
| Registrar cuenta           | POST   | /auth/register         | No             |
| Iniciar sesión             | POST   | /auth/login            | No             |
| Solicitar código de recuperación | POST | /auth/recuperar    | No             |
| Restablecer contraseña     | POST   | /auth/restablecer      | No             |
| Consultar versión modelo   | GET    | /model/version         | Sí             |
| Descargar modelo tflite    | GET    | /model/latest          | Sí             |
| Subir pesos FL             | POST   | /federated/upload      | Sí             |
| Estado agregación FL       | GET    | /federated/status      | Sí             |
| Descargar modelo post-FL   | GET    | /federated/model       | Sí             |

### Flujo de actualización del modelo
1. Al abrir la app: `GET /model/version` → comparar con `estado_modelo_fl.version_local`.
2. Si `version_servidor > version_local`: descargar `GET /model/latest?formato=tflite`.
3. Guardar en documentos, actualizar `estado_modelo_fl`, reiniciar `InferenciaLocal`.
4. Registrar en `historial_sincronizacion`.

### Flujo de subida de pesos FL
1. Usuario completa N diagnósticos (mínimo configurable, recomendado 5).
2. `fedavg_local.dart` entrena sobre las últimas sesiones locales.
3. Mostrar diálogo de consentimiento explícito antes de subir.
4. `POST /federated/upload` con `{id_cliente, ronda, numero_muestras, pesos}`.
5. Si respuesta exitosa: limpiar pesos temporales, registrar en `historial_sincronizacion`.

---

## Prohibiciones absolutas

- No enviar datos personales, clínicos o de diagnóstico al backend.
- No almacenar el token JWT en `SharedPreferences` ni en variables globales sin cifrado.
- No usar `http` directamente fuera de `cliente_api.dart`.
- No ejecutar SQL fuera de los repositorios.
- No mezclar lógica de negocio dentro de widgets.
- No usar `BuildContext` después de un `await` sin verificar `mounted`.
- No bloquear el hilo principal con operaciones de archivo o DB (usar `compute` o `Isolate` si > 16ms).
- No mostrar probabilidades de CAD como diagnóstico médico definitivo. Siempre acompañar con aviso de consulta profesional.
- No solicitar permisos de cámara, micrófono o ubicación sin flujo de consentimiento explicado.
- No hardcodear la URL del backend. Usar `constantes.dart`.
