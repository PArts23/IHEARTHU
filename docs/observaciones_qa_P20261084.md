# Observaciones QA P20261084 (12/11/2026) → corrección

Las 13 observaciones se reportaron sobre la rama `main` (commit `450f211`), que todavía no incluye el PR #2 (`casos-prueba-v3`). Las pantallas citadas ("Evaluar Salud", "Modelo de Aprendizaje Federado", "Modelo de Inferencia FL") solo existen en esa versión anterior. Con el PR #2 fusionado, la app queda así:

| Id. | CP | Corrección | Dónde |
|-----|----|------------|-------|
| 3283 | CP032 | Flecha '<' en la barra superior de "Historial médico"; vuelve a la pestaña anterior. | `pantalla_inicio.dart` (`_volver`) |
| 3284 | CP037 | Cada pregunta sin responder muestra "Respuesta requerida" con borde rojo, la tarjeta de frecuencia muestra "Registre su frecuencia cardíaca", aparece el aviso general y la pantalla se desplaza a la primera pregunta pendiente. | `pantalla_cuestionario.dart`, `pregunta_opciones.dart` |
| 3285 | CP038 | Flecha '<' en "Iniciar diagnóstico"; vuelve a Inicio y descarta el formulario. | `pantalla_inicio.dart` |
| 3286 | CP043 | Peso solo numérico y entre 20 y 300 kg; "Ingrese un valor de peso válido" y bloqueo del guardado. | `validadores.dart`, `pantalla_perfil.dart` |
| 3287 | CP045 | Altura solo numérica y entre 0.5 y 2.5 m; "Ingrese una altura válida" y bloqueo del guardado. | `validadores.dart`, `pantalla_perfil.dart` |
| 3288 | CP046 | Diálogo "¿Desea salir sin guardar los cambios?" (No/Sí) al usar la flecha, la barra inferior o el botón atrás del sistema. | `pantalla_inicio.dart`, `pantalla_perfil.dart` |
| 3289 | CP047 | La tarjeta "Mi perfil" muestra nombre, correo y resumen (edad, sexo, IMC) y el botón "Editar". | `pantalla_ajustes.dart` |
| 3290 | CP050 | El texto "El sistema está calibrado correctamente y las notificaciones de emergencia están activadas." aparece en la tarjeta "Revisar modelo federado" y en la pantalla "Modelo predictivo FL". Los datos del wearable IoT se movieron a "Vinculación IoT"; en Modelo FL solo queda el teléfono local, al final de la pantalla. | `pantalla_ajustes.dart`, `pantalla_modelo_fl.dart`, `pantalla_iot.dart` |
| 3291 | CP051 | Diálogo "¿Está seguro que desea cerrar sesión?" con Cancelar/Confirmar. | `pantalla_ajustes.dart` |
| 3292 | CP053 | Flecha '<' en "Configuración" (pestaña Ajustes); vuelve a la pestaña anterior. | `pantalla_inicio.dart` |
| 3293 | CP056 | Flecha '<' en "Mis diagnósticos"; vuelve a Inicio. La barra inferior queda visible con Historial resaltado. | `pantalla_mis_diagnosticos.dart` |
| 3294 | CP059 | Tarjeta del dispositivo local: nombre del teléfono, Conectado/Desconectado, batería en tiempo real y "PPG activo". | `pantalla_modelo_fl.dart`, `servicio_dispositivo_local.dart`, `MainActivity.kt` |
| 3295 | CP065 | "Vinculación IoT" con "BUSCAR DISPOSITIVOS (IoT)", "Buscando dispositivos..." y la lista "Dispositivos en Rango" (nombre, MAC, RSSI). | `pantalla_iot.dart`, `servicio_wearable.dart` |
