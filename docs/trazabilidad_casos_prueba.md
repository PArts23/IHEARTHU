# Trazabilidad: Casos de Prueba v3.1 → Aplicación móvil

Documento de casos alineado: `docs/Casos_de_Prueba_v3.1.xlsx` (la hoja "CONTROL DE CAMBIOS" lista cada celda corregida respecto a la v3.0).

Leyenda de estado: **App** = cubierto íntegramente en la app · **App + Backend** = la app está lista y depende de un endpoint/regla del backend · **App + Hardware** = requiere wearable/Bluetooth real para validarse · **Observación** = el caso tiene una inconsistencia que conviene corregir en el documento.

| CP | Caso | Implementación | Estado |
|----|------|----------------|--------|
| CP001 | Login exitoso | `pantalla_login.dart` → `ProveedorEstado.iniciarSesion` → `/inicio` | App + Backend |
| CP002 | Contraseña incorrecta | `ServicioAuth.iniciarSesion` traduce 401/404/422 a "Credenciales inválidas. Por favor verifique su correo y contraseña" | App + Backend |
| CP003 | Correo no registrado | Mismo mensaje genérico de credenciales inválidas | App + Backend |
| CP004 | Correo inválido | `Validadores.correo` → "Ingrese un correo electrónico válido" | App |
| CP005 | Campos vacíos | "El correo electrónico es obligatorio" / "La contraseña es obligatoria" | App |
| CP006 | Ir a registro | Enlace "Registrar una nueva cuenta" → `/registro` | App |
| CP007 | Ir a recuperación | "Olvidé mi contraseña" → `/recuperar` | App |
| CP008 | Login sin internet | `ClienteApi` captura `SocketException`/`ClientException` → "Sin conexión a internet. Verifique su red para autenticarse" | App |
| CP009 | Registro exitoso | Botón "Crear nueva cuenta"; tras registrar inicia sesión y abre "Mi perfil" para completarlo | App + Backend (correo de bienvenida) |
| CP010 | Registro con campos vacíos | Validación inline en todos los campos + aviso general | App |
| CP011 | DNI inválido | Teclado numérico, solo dígitos, máx. 8; "El DNI debe contener exactamente 8 dígitos numéricos" | App |
| CP012 | DNI ya registrado | `ServicioAuth._traducirDuplicado` → "El número de DNI ingresado ya se encuentra registrado en el sistema" | App + Backend (409 que mencione "dni") |
| CP013 | Correo ya registrado | → "El correo electrónico ya se encuentra registrado. Intente con otro o inicie sesión" | App + Backend (409 que mencione "correo") |
| CP014 | Confirmación distinta | "Las contraseñas no coinciden. Por favor verifique" | App |
| CP015 | Contraseña insegura | Política: ≥8, número, mayúscula y carácter especial | App (subir la misma regla al backend) |
| CP016 | "Ya tengo una cuenta" | Botón en registro → `/login` | App |
| CP017 | Recuperación exitosa | `POST /auth/recuperar` → confirmación + pantalla de código | App + Backend |
| CP018 | Correo vacío | "El correo electrónico es obligatorio" | App |
| CP019 | Correo inválido | "Ingrese un correo electrónico válido" | App |
| CP020 | Correo no registrado | 404 → "El correo electrónico ingresado no se encuentra registrado" | App + Backend |
| CP021 | Cancelar | Botón "Cancelar" → `/login` | App |
| CP022 | Solicitudes consecutivas | Espera de 60 s en la app y 429 del backend → "Por favor espere X segundos antes de solicitar otro código" | App + Backend |
| CP023 | Recuperación sin internet | "No hay conexión a internet. Verifique su red para solicitar el restablecimiento" | App |
| CP024 | Tarjeta de riesgo CAD | `TarjetaRiesgo` (badge Normal/CAD, %, tiempo desde el último diagnóstico) + `TarjetaSignoVital` con indicador de estado | App |
| CP025 | Iniciar diagnóstico | Perfil calibrado → pestaña Evaluar; si no → calibración | App |
| CP026–CP029, CP071 | Barra inferior | `PantallaInicio` (Inicio, Evaluar, Historial, Perfil, Ajustes/"Configuración") | App |
| CP030 | Ver todas | "Ver todas" → `PantallaMisDiagnosticos` con buscador, rango de fechas y tipo | App |
| CP031 | Exportar PDF | Diálogo → `GeneradorReportePdf` → menú nativo de compartir | App |
| CP032 | Flecha en Historial médico | Regresa a la pestaña anterior | App |
| CP033 | Desconexión PPG y reconexión | `ServicioWearable` (autoConnect) + `TarjetaPpgEnVivo` ("— Sensor desconectado", lecturas "--", aviso y reconexión) | App + Hardware |
| CP034 | Historial vacío | "Aún no se cuenta con registros de monitoreo." | App |
| CP035–CP036 | Formulario con/sin dolor | Preguntas sin respuesta por defecto; dolor "No" desactiva frecuencia y clasificación; obesidad calculada por IMC | App |
| CP037 | Formulario incompleto | "Por favor, responda todas las preguntas antes de continuar" + preguntas pendientes resaltadas | App |
| CP038 | Flecha en Iniciar diagnóstico | Vuelve a Inicio y descarta el formulario | App |
| CP039–CP040 | Actualizar perfil / IMC | IMC de solo lectura, calculado en vivo y redondeado a un decimal (24.5 / 22.9) | App |
| CP041 | Campos vacíos | "El nombre completo es obligatorio" e IMC "--" | App |
| CP042–CP045 | Peso/altura inválidos o atípicos | Solo números; peso 20–300 kg; altura 0,5–2,5 m | App |
| CP046 | Salir con cambios | "¿Desea salir sin guardar los cambios?" Sí/No | App |
| CP047 | Editar perfil desde Configuración | Botón "Editar" → pestaña Mi perfil | App |
| CP048 | Notificaciones | Switch persistente; al activarlo solicita el permiso del sistema | App |
| CP049 | Dispositivos vinculados | Nombre del wearable + "Sincronización completa" → "Vinculación IoT" | App + Hardware |
| CP050 | Revisar modelo federado | Texto de estado → "Modelo predictivo FL" | App |
| CP051–CP052 | Cerrar sesión | "¿Está seguro que desea cerrar sesión?" Cancelar/Confirmar | App |
| CP053 | Flecha en Configuración | Regresa a la pestaña anterior | App |
| CP054–CP055 | Comparativa de sesiones | `TablaComparativaSesiones` (Parámetro / Penúltima sesión / Última sesión; "Sin registro previo" y "--") | App |
| CP056 | Flecha en Mis diagnósticos | Regresa a Inicio; barra inferior con Historial resaltado | App |
| CP057 | Banner FL | "Federated Learning activo", aviso de privacidad, fecha y hora de la última sincronización | App |
| CP058 | Métricas | Accuracy, Precision, Recall y F1-Score con indicador y descripción | App · **Pendiente:** valor de Accuracy |
| CP059 | Dispositivo local | Nombre del teléfono, Conectado, batería en tiempo real, "PPG activo" | App |
| CP060 | Nodo FL sin conexión | "Fuera de línea" / "Sincronización pausada"; indicadores en ámbar | App |
| CP061 | Flecha en Modelo FL | Regresa a Configuración | App |
| CP062 | Calibración exitosa | Textos exactos, checklist y paso automático a Evaluar | App + Hardware |
| CP063 | Perfil incompleto | "Datos de perfil incompletos" y el proceso se interrumpe | App |
| CP064 | Sensor desconectado | Pausa + "Verifique la conexión de su dispositivo" + "Reintentar" | App + Hardware |
| CP065–CP066 | Buscar y vincular | "BUSCAR DISPOSITIVOS (IoT)", lista con MAC y RSSI, PIN del sistema | App + Hardware |
| CP067 | Bluetooth apagado | Tarjeta "Desconectado / Bluetooth apagado" + diálogo "Activar Bluetooth para buscar dispositivos IoT" | App + Hardware |
| CP068 | Flecha en Health Connect | Vuelve a Configuración con Ajustes resaltado | App |
| CP069–CP070 | Informe de salud | Avatar con iniciales, "Informe de salud: <nombre>", HRV, Avg HR, riesgo, ≥2 recomendaciones y aviso legal | App |
| CP072 | Exportar sin datos | Mensaje de datos insuficientes; no se genera archivo | App |

## Inconsistencias resueltas en la v3.1

| Tema | Decisión |
|------|----------|
| Redondeo del IMC (CP039 vs CP040) | Un decimal con redondeo en ambos: 24.5 y 22.9. Se agregó a CP040 la altura de 1.75 m como precondición. |
| Contraseña de CP002 | Dato cambiado a `ClaveErronea2026*` para cumplir la política de CP015. El login solo valida que la contraseña no esté vacía. |
| Redacción de preguntas (CP035 vs CP069) | CP069 usa la misma redacción que CP035 y que la app. Las opciones de frecuencia (1–5) y tipo de dolor reflejan las de la app. |
| ECG vs PPG | La app no captura ECG; CP025, CP027, CP054 y CP066 hablan de PPG / evaluación cardíaca. |
| Nombre de la aplicación | "I HEAR(TH) U" en el login, la cabecera de Inicio, el título de la app y la etiqueta de Android. |
| Formato del porcentaje de riesgo | Un decimal con espacio ("18.0 %") en Inicio, el informe, el historial, la tabla comparativa y el PDF. |
| Nombres de pantallas | 'Registro de paciente', 'Recuperación de contraseña', 'Restablecer contraseña', 'Historial médico', 'Mis diagnósticos', 'Configuración', 'Modelo predictivo FL', 'Dispositivos Vinculados'. |
| Perfil "cifrado localmente" (CP009) | El perfil se almacena en SQLite local sin cifrar; el caso describe ahora "almacenado localmente". |
| Exportación PDF (CP031) | Se eliminaron los permisos de almacenamiento y `file_picker`; el PDF se comparte por el menú nativo. |
| Rondas federadas (CP050) | La pantalla del modelo FL muestra la ronda federada y la versión del modelo. |
| Estado vacío (CP034) | El mensaje exacto se muestra en su propia línea; la instrucción va debajo. |
| Wearable | Nombre oficial "Xiaomi Smart Band 10". |

## Pendiente

- **CP058 – Accuracy:** el valor del modelo global no está registrado en el proyecto. Completar `Constantes.accuracyModeloGlobal` en `lib/nucleo/constantes.dart`; mientras tanto la métrica muestra "--". Se dejó de usar el valor de `accuracyLocal`, que `fedavg_local.dart` genera de forma aleatoria.
- **CP059:** la app muestra el nombre del dispositivo configurado en Android ("Redmi Note 10") y, si no existe, el modelo técnico.
