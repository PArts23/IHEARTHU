import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/red/cliente_api.dart';

class ResultAuth {
  final String token;
  final String expiraEn;
  final int usuarioId;
  final String nombreCompleto;
  final String numeroDni;
  final String correo;

  const ResultAuth({
    required this.token,
    required this.expiraEn,
    required this.usuarioId,
    required this.nombreCompleto,
    required this.numeroDni,
    required this.correo,
  });

  factory ResultAuth.desdeMapa(Map<String, dynamic> mapa) {
    final tokenVal = mapa['token'] ?? mapa['access_token'];
    final expiraVal = mapa['expira_en'];
    final usuarioIdVal = mapa['usuario_id'];
    final nombreVal = mapa['nombre_completo'];
    final dniVal = mapa['numero_dni'];
    final correoVal = mapa['correo'];

    return ResultAuth(
      token: tokenVal is String ? tokenVal : '',
      expiraEn: expiraVal is String ? expiraVal : DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      usuarioId: usuarioIdVal is int ? usuarioIdVal : 1,
      nombreCompleto: nombreVal is String ? nombreVal : '',
      numeroDni: dniVal is String ? dniVal : '',
      correo: correoVal is String ? correoVal : '',
    );
  }
}

class ServicioAuth {
  static final Map<String, DateTime> _ultimasSolicitudesRecuperacion = {};

  final ClienteApi _cliente = ClienteApi.instancia;
  final FlutterSecureStorage _almacenamiento = const FlutterSecureStorage();

  Future<ResultAuth> iniciarSesion(String correo, String contrasena) async {
    try {
      return await _iniciarSesionEnServidor(correo, contrasena);
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
    } on ErrorAutenticacionException {
      await _almacenamiento.delete(key: Constantes.claveTokenJwt);
      throw ErrorAutenticacionException(Constantes.mensajeCredencialesInvalidas);
    } on ErrorNoEncontradoException {
      throw ErrorAutenticacionException(Constantes.mensajeCredencialesInvalidas);
    } on ErrorValidacionException {
      throw ErrorAutenticacionException(Constantes.mensajeCredencialesInvalidas);
    }
  }

  Future<ResultAuth> _iniciarSesionEnServidor(String correo, String contrasena) async {
    final respuesta = await _cliente.post(
      '/auth/login',
      cuerpo: {
        'correo': correo.trim().toLowerCase(),
        'contrasena': contrasena,
      },
      requiereAuth: false,
    );

    final decodificado = jsonDecode(respuesta.body);
    final mapa = decodificado is Map<String, dynamic> ? decodificado : <String, dynamic>{};
    final tokenVal = mapa['token'];
    final token = tokenVal is String ? tokenVal : '';

    if (token.isEmpty) {
      throw ErrorAutenticacionException(Constantes.mensajeCredencialesInvalidas);
    }
    await _almacenamiento.write(key: Constantes.claveTokenJwt, value: token);

    final respuestaMe = await _cliente.get(
      '/auth/me',
      requiereAuth: true,
    );

    final decodificadoMe = jsonDecode(respuestaMe.body);
    final mapaMe = decodificadoMe is Map<String, dynamic> ? decodificadoMe : <String, dynamic>{};
    final idVal = mapaMe['id'];
    final nombreVal = mapaMe['nombre_completo'];
    final dniVal = mapaMe['numero_dni'];
    final correoVal = mapaMe['correo'];

    return ResultAuth(
      token: token,
      expiraEn: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      usuarioId: idVal is int ? idVal : 0,
      nombreCompleto: nombreVal is String ? nombreVal : '',
      numeroDni: dniVal is String ? dniVal : '',
      correo: correoVal is String ? correoVal : '',
    );
  }

  Future<void> registrarUsuario({
    required String nombreCompleto,
    required String numeroDni,
    required String correo,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    try {
      await _cliente.post(
        '/auth/register',
        cuerpo: {
          'nombre_completo': nombreCompleto.trim(),
          'numero_dni': numeroDni.trim(),
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
          'confirmar_contrasena': confirmarContrasena,
        },
        requiereAuth: false,
      );
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
    } on ErrorConflictoException catch (error) {
      throw ErrorConflictoException(_traducirDuplicado(error.mensaje));
    } on ErrorValidacionException catch (error) {
      final traducido = _traducirDuplicado(error.mensaje);
      if (traducido != error.mensaje) {
        throw ErrorConflictoException(traducido);
      }
      rethrow;
    }
  }

  String _traducirDuplicado(String mensaje) {
    final texto = mensaje.toLowerCase();
    final esDuplicado = texto.contains('registrad') ||
        texto.contains('existe') ||
        texto.contains('already') ||
        texto.contains('duplic') ||
        texto.contains('uso');
    if (!esDuplicado) return mensaje;
    if (texto.contains('dni')) return Constantes.mensajeDniRegistrado;
    if (texto.contains('correo') || texto.contains('email')) return Constantes.mensajeCorreoRegistrado;
    return mensaje;
  }

  int segundosRestantesRecuperacion(String correo) {
    final ultima = _ultimasSolicitudesRecuperacion[correo.trim().toLowerCase()];
    if (ultima == null) return 0;
    final transcurridos = DateTime.now().difference(ultima).inSeconds;
    final restantes = Constantes.segundosEsperaReenvioCodigo - transcurridos;
    return restantes > 0 ? restantes : 0;
  }

  Future<void> solicitarRecuperacion(String correo) async {
    final correoNormalizado = correo.trim().toLowerCase();
    final restantes = segundosRestantesRecuperacion(correoNormalizado);
    if (restantes > 0) {
      throw ErrorEsperaException(
        'Por favor espere $restantes segundos antes de solicitar otro código',
        restantes,
      );
    }
    try {
      await _cliente.post(
        '/auth/recuperar',
        cuerpo: {'correo': correoNormalizado},
        requiereAuth: false,
      );
      _ultimasSolicitudesRecuperacion[correoNormalizado] = DateTime.now();
    } on ErrorNoEncontradoException {
      throw ErrorNoEncontradoException(Constantes.mensajeCorreoNoRegistrado);
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionRecuperacion);
    } on ErrorDemasiadasSolicitudesException {
      _ultimasSolicitudesRecuperacion[correoNormalizado] = DateTime.now();
      throw ErrorEsperaException(
        'Por favor espere ${Constantes.segundosEsperaReenvioCodigo} segundos antes de solicitar otro código',
        Constantes.segundosEsperaReenvioCodigo,
      );
    }
  }

  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      await _cliente.post(
        '/auth/restablecer',
        cuerpo: {
          'correo': correo.trim().toLowerCase(),
          'codigo': codigo.trim(),
          'nueva_contrasena': nuevaContrasena,
          'confirmar_contrasena': confirmarContrasena,
        },
        requiereAuth: false,
      );
    } on ErrorNoEncontradoException {
      throw ErrorNoEncontradoException(Constantes.mensajeCorreoNoRegistrado);
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionRecuperacion);
    }
  }
}

class ErrorEsperaException implements Exception {
  final String mensaje;
  final int segundosRestantes;

  ErrorEsperaException(this.mensaje, this.segundosRestantes);

  @override
  String toString() => mensaje;
}
