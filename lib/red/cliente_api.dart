import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/nucleo/constantes.dart';

class ClienteApi {
  static final ClienteApi instancia = ClienteApi._interna();
  final http.Client _clienteHttp = http.Client();
  final FlutterSecureStorage _almacenamientoSeguro = const FlutterSecureStorage();

  ClienteApi._interna();

  Future<Map<String, String>> _obtenerCabeceras(bool requiereAuth) async {
    final cabeceras = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiereAuth) {
      final token = await _almacenamientoSeguro.read(key: Constantes.claveTokenJwt);
      if (token != null) {
        cabeceras['Authorization'] = 'Bearer $token';
      }
    }
    return cabeceras;
  }

  void _evaluarRespuesta(http.Response respuesta) {
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return;
    }

    switch (respuesta.statusCode) {
      case 400:
        throw ErrorValidacionException(_obtenerMensajeError(respuesta.body) ?? 'Solicitud inválida.');
      case 401:
        throw ErrorAutenticacionException('Sesión no autorizada o expirada.');
      case 409:
        throw ErrorConflictoException(_obtenerMensajeError(respuesta.body) ?? 'Conflicto de datos en el servidor.');
      case 404:
        throw ErrorNoEncontradoException('Recurso no encontrado en el servidor.');
      case 422:
        throw ErrorValidacionException(_obtenerMensajeError(respuesta.body) ?? 'Datos de solicitud inválidos.');
      case 429:
        throw ErrorDemasiadasSolicitudesException(_obtenerMensajeError(respuesta.body) ?? 'Demasiados intentos. Espere unos minutos e intente de nuevo.');
      case 500:
        throw ErrorServidorException('Error interno del servidor. Por favor, intente más tarde.');
      default:
        throw ErrorConexionException('Error inesperado (${respuesta.statusCode}): ${respuesta.reasonPhrase}');
    }
  }

  String _traducirError(String campo, String mensajeOriginal) {
    final campoTraducido = _traducirCampo(campo);
    final mensajeTraducido = _traducirMensaje(mensajeOriginal);
    if (campoTraducido.isNotEmpty) {
      return '$campoTraducido: $mensajeTraducido';
    }
    return mensajeTraducido;
  }

  String _traducirCampo(String campo) {
    switch (campo) {
      case 'nombre_completo':
        return 'Nombre completo';
      case 'numero_dni':
        return 'Número de DNI';
      case 'correo':
        return 'Correo electrónico';
      case 'contrasena':
        return 'Contraseña';
      case 'confirmar_contrasena':
        return 'Confirmar contraseña';
      case 'id_cliente':
        return 'ID de cliente';
      case 'ronda':
        return 'Ronda';
      case 'numero_muestras':
        return 'Número de muestras';
      case 'pesos':
        return 'Pesos';
      default:
        return campo;
    }
  }

  String _traducirMensaje(String mensaje) {
    final msgLower = mensaje.toLowerCase();
    if (msgLower.contains('field required') || msgLower == 'missing') {
      return 'es obligatorio';
    }
    if (msgLower.contains('value is not a valid email address') || msgLower.contains('value_error.email')) {
      return 'no es un correo electrónico válido';
    }
    if (msgLower.contains('string_too_short')) {
      return 'es demasiado corto';
    }
    if (msgLower.contains('at least')) {
      return 'debe tener al menos más caracteres';
    }
    return mensaje;
  }

  String? _obtenerMensajeError(String cuerpo) {
    try {
      final datos = jsonDecode(cuerpo);
      if (datos is Map && datos.containsKey('detail')) {
        final detalle = datos['detail'];
        if (detalle is List) {
          final mensajes = <String>[];
          for (final item in detalle) {
            if (item is Map) {
              final msg = item['msg']?.toString() ?? 'Error';
              final loc = item['loc'];
              final campo = (loc is List && loc.isNotEmpty) ? loc.last.toString() : '';
              final esNumero = int.tryParse(campo) != null;
              if (campo.isNotEmpty && campo != 'body' && !esNumero) {
                mensajes.add(_traducirError(campo, msg));
              } else {
                mensajes.add(_traducirMensaje(msg));
              }
            } else {
              mensajes.add(item.toString());
            }
          }
          return mensajes.join(', ');
        }
        return detalle.toString();
      }
    } catch (_) {}
    return null;
  }


  Future<http.Response> get(String ruta, {bool requiereAuth = true}) async {
    try {
      final url = Uri.parse('${Constantes.urlBaseBackend}$ruta');
      final cabeceras = await _obtenerCabeceras(requiereAuth);
      
      final respuesta = await _clienteHttp
          .get(url, headers: cabeceras)
          .timeout(const Duration(seconds: 30));

      _evaluarRespuesta(respuesta);
      return respuesta;
    } on TimeoutException {
      throw ErrorConexionException('Tiempo de espera agotado. Verifique su conexión.');
    } on SocketException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexion);
    } on http.ClientException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexion);
    } catch (e) {
      if (e is! Exception) {
        throw ErrorConexionException('Error de conexión desconocido.');
      }
      rethrow;
    }
  }

  Future<http.Response> post(String ruta, {Object? cuerpo, bool requiereAuth = true}) async {
    try {
      final url = Uri.parse('${Constantes.urlBaseBackend}$ruta');
      final cabeceras = await _obtenerCabeceras(requiereAuth);
      final cuerpoJson = cuerpo != null ? jsonEncode(cuerpo) : null;

      final respuesta = await _clienteHttp
          .post(url, headers: cabeceras, body: cuerpoJson)
          .timeout(const Duration(seconds: 30));

      _evaluarRespuesta(respuesta);
      return respuesta;
    } on TimeoutException {
      throw ErrorConexionException('Tiempo de espera agotado. Verifique su conexión.');
    } on SocketException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexion);
    } on http.ClientException {
      throw ErrorSinConexionException(Constantes.mensajeSinConexion);
    } catch (e) {
      if (e is! Exception) {
        throw ErrorConexionException('Error de conexión desconocido.');
      }
      rethrow;
    }
  }
}

class ErrorAutenticacionException implements Exception {
  final String mensaje;
  ErrorAutenticacionException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorConflictoException implements Exception {
  final String mensaje;
  ErrorConflictoException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorNoEncontradoException implements Exception {
  final String mensaje;
  ErrorNoEncontradoException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorValidacionException implements Exception {
  final String mensaje;
  ErrorValidacionException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorServidorException implements Exception {
  final String mensaje;
  ErrorServidorException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorConexionException implements Exception {
  final String mensaje;
  ErrorConexionException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ErrorSinConexionException extends ErrorConexionException {
  ErrorSinConexionException(super.mensaje);
}

class ErrorDemasiadasSolicitudesException implements Exception {
  final String mensaje;
  ErrorDemasiadasSolicitudesException(this.mensaje);

  @override
  String toString() => mensaje;
}
