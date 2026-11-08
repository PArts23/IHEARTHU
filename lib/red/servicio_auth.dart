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
  final ClienteApi _cliente = ClienteApi.instancia;
  final FlutterSecureStorage _almacenamiento = const FlutterSecureStorage();

  Future<ResultAuth> iniciarSesion(String correo, String contrasena) async {
    try {
      return await _iniciarSesionEnServidor(correo, contrasena);
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
    }
  }

  Future<ResultAuth> _iniciarSesionEnServidor(String correo, String contrasena) async {
    final respuesta = await _cliente.post(
      '/auth/login',
      cuerpo: {
        'correo': correo,
        'contrasena': contrasena,
      },
      requiereAuth: false,
    );

    final decodificado = jsonDecode(respuesta.body);
    final mapa = decodificado is Map<String, dynamic> ? decodificado : <String, dynamic>{};
    final tokenVal = mapa['token'];
    final token = tokenVal is String ? tokenVal : '';

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
          'nombre_completo': nombreCompleto,
          'numero_dni': numeroDni,
          'correo': correo,
          'contrasena': contrasena,
          'confirmar_contrasena': confirmarContrasena,
        },
        requiereAuth: false,
      );
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
    }
  }

  Future<void> solicitarRecuperacion(String correo) async {
    try {
      await _cliente.post(
        '/auth/recuperar',
        cuerpo: {'correo': correo.trim().toLowerCase()},
        requiereAuth: false,
      );
    } on ErrorNoEncontradoException {
      throw ErrorNoEncontradoException('No existe una cuenta registrada con este correo electrónico.');
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
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
      throw ErrorNoEncontradoException('No existe una cuenta registrada con este correo electrónico.');
    } on ErrorSinConexionException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexionAutenticacion);
    }
  }
}
