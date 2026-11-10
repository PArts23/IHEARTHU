# Trazabilidad: Casos de Prueba v3.0 → Aplicación móvil

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
| CP039–CP040 | Actualizar perfil / IMC | IMC de solo lectura, calculado en vivo | App · **Observación CP040** |
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
| CP058 | Métricas | Accuracy, Precision, Recall y F1-Score con indicador y descripción | App · **Observación** (valor de Accuracy) |
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

## Observaciones sobre el documento de casos de prueba

1. **CP039 y CP040 usan reglas de redondeo distintas.** 75 / 1,75² = 24,49 → CP039 espera 24,5 (redondeo). 70 / 1,75² = 22,86 → CP040 espera 22,8 (truncamiento). La app redondea a un decimal, así que muestra 24,5 y 22,9. Sugerencia: cambiar el resultado esperado de CP040 a 22,9.
2. **CP058:** el valor de Accuracy del modelo global no está registrado. `Constantes.accuracyModeloGlobal` está vacío y la pantalla muestra "--" hasta que se complete. Precision (0,649), Recall (0,867) y F1 (0,742) provienen de las métricas validadas.
3. **CP035 y CP069** redactan distinto las mismas preguntas. La app usa la redacción de CP035–CP037, que aparece en más casos.
4. **CP002** usa la contraseña "ClaveErronea2026", que no cumple la política de CP015. Por eso el login solo valida que la contraseña no esté vacía y deja la verificación al backend.
5. **CP059** espera el nombre comercial ("Redmi Note 10"). La app lo toma del nombre del dispositivo configurado en Android y, si no existe, usa el modelo técnico.
