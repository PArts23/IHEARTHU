import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/nucleo/constantes.dart';

class RepositorioPreferencias {
  final FlutterSecureStorage _almacenamiento = const FlutterSecureStorage();

  Future<bool> _leerBooleano(String clave, bool porDefecto) async {
    try {
      final valor = await _almacenamiento.read(key: clave);
      if (valor == null) return porDefecto;
      return valor == 'true';
    } catch (_) {
      return porDefecto;
    }
  }

  Future<void> _escribirBooleano(String clave, bool valor) async {
    try {
      await _almacenamiento.write(key: clave, value: valor.toString());
    } catch (_) {}
  }

  Future<bool> obtenerPerfilCalibrado() => _leerBooleano(Constantes.clavePerfilCalibrado, false);

  Future<void> guardarPerfilCalibrado(bool calibrado) =>
      _escribirBooleano(Constantes.clavePerfilCalibrado, calibrado);

  Future<bool> obtenerNotificacionesActivas() =>
      _leerBooleano(Constantes.claveNotificacionesActivas, true);

  Future<void> guardarNotificacionesActivas(bool activas) =>
      _escribirBooleano(Constantes.claveNotificacionesActivas, activas);

  Future<void> limpiar() async {
    try {
      await _almacenamiento.delete(key: Constantes.clavePerfilCalibrado);
    } catch (_) {}
  }
}
