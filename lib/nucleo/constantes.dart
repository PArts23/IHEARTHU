class Constantes {
  static const String urlBaseBackend = 'https://i-heart-127320450404.europe-west1.run.app';
  static const String hostBackend = 'i-heart-127320450404.europe-west1.run.app';

  static const String claveTokenJwt = 'token_jwt';
  static const String claveTokenExpira = 'token_expira';
  static const String clavePerfilCalibrado = 'perfil_calibrado';
  static const String claveNotificacionesActivas = 'notificaciones_activas';

  static const int duracionLimiteSincronizacionHoras = 24;
  static const int cantidadMinimaSesionesEntrenamiento = 5;

  static const int longitudMinimaContrasena = 8;
  static const int longitudCodigoVerificacion = 6;
  static const int longitudDni = 8;
  static const int segundosEsperaReenvioCodigo = 60;

  static const double pesoMinimoKg = 20;
  static const double pesoMaximoKg = 300;
  static const double alturaMinimaM = 0.5;
  static const double alturaMaximaM = 2.5;
  static const int edadMinima = 18;
  static const int edadMaxima = 120;
  static const double imcUmbralObesidad = 30;

  static const String mensajeSinConexion = 'Sin conexión a internet. Verifique su red.';
  static const String mensajeSinConexionAutenticacion =
      'Sin conexión a internet. Verifique su red para autenticarse';
  static const String mensajeSinConexionRecuperacion =
      'No hay conexión a internet. Verifique su red para solicitar el restablecimiento';
  static const String mensajeCredencialesInvalidas =
      'Credenciales inválidas. Por favor verifique su correo y contraseña';
  static const String mensajeCorreoObligatorio = 'El correo electrónico es obligatorio';
  static const String mensajeCorreoInvalido = 'Ingrese un correo electrónico válido';
  static const String mensajeContrasenaObligatoria = 'La contraseña es obligatoria';
  static const String mensajeContrasenaInsegura =
      'La contraseña debe tener al menos 8 caracteres, incluir números, mayúsculas y un carácter especial';
  static const String mensajeContrasenasNoCoinciden = 'Las contraseñas no coinciden. Por favor verifique';
  static const String mensajeDniInvalido = 'El DNI debe contener exactamente 8 dígitos numéricos';
  static const String mensajeDniRegistrado = 'El número de DNI ingresado ya se encuentra registrado en el sistema';
  static const String mensajeCorreoRegistrado =
      'El correo electrónico ya se encuentra registrado. Intente con otro o inicie sesión';
  static const String mensajeCorreoNoRegistrado = 'El correo electrónico ingresado no se encuentra registrado';
  static const String mensajeNombreObligatorio = 'El nombre completo es obligatorio';
  static const String mensajePesoInvalido = 'Ingrese un valor de peso válido';
  static const String mensajeAlturaInvalida = 'Ingrese una altura válida';
  static const String mensajeEdadInvalida = 'Ingrese una edad válida';
  static const String mensajeCuestionarioIncompleto = 'Por favor, responda todas las preguntas antes de continuar';
  static const String mensajePerfilIncompleto = 'Datos de perfil incompletos';
  static const String mensajeVerifiqueDispositivo = 'Verifique la conexión de su dispositivo';
  static const String mensajeSinRegistrosMonitoreo = 'Aún no se cuenta con registros de monitoreo.';
  static const String mensajeSinDatosReporte =
      'No hay datos suficientes para generar el reporte. Realice al menos un diagnóstico.';
  static const String avisoLegalRiesgo =
      'La estimación de riesgo es meramente informativa. Consulte a un profesional de la salud.';

  static const String nombreAplicacion = 'I HEAR(TH) U';

  static const double? accuracyModeloGlobal = null;

  static String formatearPorcentaje(double fraccion) => '${(fraccion * 100).toStringAsFixed(1)} %';
  static const double precisionModeloGlobal = 0.649;
  static const double recallModeloGlobal = 0.867;
  static const double f1ModeloGlobal = 0.742;
}
