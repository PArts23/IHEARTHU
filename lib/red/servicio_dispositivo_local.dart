import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class ServicioDispositivoLocal {
  static final ServicioDispositivoLocal instancia = ServicioDispositivoLocal._interno();
  static const MethodChannel _canal = MethodChannel('iheart/dispositivo');

  final DeviceInfoPlugin _informacion = DeviceInfoPlugin();
  String? _modeloEnCache;

  ServicioDispositivoLocal._interno();

  Future<String> obtenerModelo() async {
    final enCache = _modeloEnCache;
    if (enCache != null) return enCache;
    try {
      String modelo = 'Smartphone';
      if (Platform.isAndroid) {
        final nombreComercial = await _obtenerNombreComercial();
        final datos = await _informacion.androidInfo;
        modelo = nombreComercial ?? datos.model;
      } else if (Platform.isIOS) {
        final datos = await _informacion.iosInfo;
        modelo = datos.utsname.machine;
      }
      _modeloEnCache = modelo;
      return modelo;
    } catch (_) {
      return 'Smartphone';
    }
  }

  Future<String?> _obtenerNombreComercial() async {
    try {
      final nombre = await _canal.invokeMethod<String>('nombreDispositivo');
      if (nombre == null || nombre.trim().isEmpty) return null;
      return nombre.trim();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<int?> obtenerNivelBateria() async {
    try {
      final nivel = await _canal.invokeMethod<int>('nivelBateria');
      if (nivel == null || nivel < 0) return null;
      return nivel;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
