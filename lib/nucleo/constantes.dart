class Constantes {
  static const String urlBaseBackend = 'https://i-heart-127320450404.europe-west1.run.app';

  static const String claveTokenJwt = 'token_jwt';
  static const String claveTokenExpira = 'token_expira';

  static const int duracionLimiteSincronizacionHoras = 24;
  static const int cantidadMinimaSesionesEntrenamiento = 5;

  static const int longitudMinimaContrasena = 8;
  static const int longitudCodigoVerificacion = 6;

  static const String mensajeSinConexion = 'Sin conexión a internet. Verifique su red.';
  static const String mensajeSinConexionAutenticacion =
      'Sin conexión a internet. Verifique su red para autenticarse';
}
