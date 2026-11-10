import 'dart:io';
import 'package:health/health.dart';

class ServicioBiometrico {
  static final ServicioBiometrico instancia = ServicioBiometrico._interno();
  final Health _health = Health();
  Future<void>? _configuracion;
  bool _solicitandoPermisos = false;

  ServicioBiometrico._interno();

  Future<void> _asegurarConfiguracion() async {
    try {
      await (_configuracion ??= _health.configure());
    } catch (error) {
      _configuracion = null;
      throw StateError('No se pudo inicializar Health Connect: $error');
    }
  }

  Future<bool> esHealthConnectDisponible() async {
    try {
      await _asegurarConfiguracion();
      final disponible = await _health.isHealthConnectAvailable();
      return disponible;
    } catch (error) {
      throw StateError('No se pudo verificar Health Connect: $error');
    }
  }

  Future<bool> solicitarAutorizacion(
    List<HealthDataType> tipos, {
    List<HealthDataAccess>? permisos,
  }) async {
    try {
      await _asegurarConfiguracion();
      final listaPermisos =
          permisos ??
          List<HealthDataAccess>.filled(tipos.length, HealthDataAccess.READ);
      if (await verificarPermisos(tipos, permisos: listaPermisos)) return true;
      if (_solicitandoPermisos) {
        throw StateError('Hay una solicitud de permisos en curso.');
      }
      _solicitandoPermisos = true;
      try {
        final autorizacion = await _health.requestAuthorization(
          tipos,
          permissions: listaPermisos,
        );
        if (Platform.isIOS) return autorizacion;
        return await verificarPermisos(tipos, permisos: listaPermisos);
      } finally {
        _solicitandoPermisos = false;
      }
    } catch (error) {
      throw StateError('No se pudo solicitar acceso a Health Connect: $error');
    }
  }

  Future<bool> verificarPermisos(
    List<HealthDataType> tipos, {
    List<HealthDataAccess>? permisos,
  }) async {
    try {
      await _asegurarConfiguracion();
      final listaPermisos =
          permisos ?? tipos.map((t) => HealthDataAccess.READ).toList();
      final tienePermisos = await _health.hasPermissions(
        tipos,
        permissions: listaPermisos,
      );
      return tienePermisos ?? false;
    } catch (error) {
      throw StateError(
        'No se pudo consultar los permisos de Health Connect: $error',
      );
    }
  }

  Future<void> revocarPermisos() async {
    try {
      await _asegurarConfiguracion();
      await _health.revokePermissions();
    } catch (error) {
      throw StateError('No se pudo revocar el acceso: $error');
    }
  }

  Future<List<HealthDataPoint>> obtenerDatosFrecuenciaCardiaca(
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      return await obtenerDatosPorTipo(HealthDataType.HEART_RATE, inicio, fin);
    } catch (error) {
      throw StateError('No se pudo leer la frecuencia cardíaca: $error');
    }
  }

  Future<List<HealthDataPoint>> obtenerDatosPorTipo(
    HealthDataType tipo,
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      await _asegurarConfiguracion();
      final datos = await _health.getHealthDataFromTypes(
        types: [tipo],
        startTime: inicio,
        endTime: fin,
      );
      datos.sort(
        (primero, segundo) => primero.dateFrom.compareTo(segundo.dateFrom),
      );
      return datos;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> escribirFrecuenciaCardiacaPrueba(
    double bpm,
    DateTime momento,
  ) async {
    try {
      final permitido = await solicitarAutorizacion(
        const [HealthDataType.HEART_RATE],
        permisos: const [HealthDataAccess.READ_WRITE],
      );
      if (!permitido) return false;
      final exito = await _health.writeHealthData(
        value: bpm,
        type: HealthDataType.HEART_RATE,
        startTime: momento,
        endTime: momento.add(const Duration(seconds: 1)),
        recordingMethod: RecordingMethod.manual,
      );
      return exito;
    } catch (error) {
      throw StateError('No se pudo escribir la lectura de prueba: $error');
    }
  }

  Future<List<double>> obtenerValoresRecientes(HealthDataType tipo, Duration ventana) async {
    try {
      final tienePermiso = await verificarPermisos([tipo]);
      if (!tienePermiso) return const [];
      final ahora = DateTime.now();
      final datos = await obtenerDatosPorTipo(tipo, ahora.subtract(ventana), ahora);
      final valores = <double>[];
      for (final punto in datos) {
        final valor = punto.value;
        if (valor is NumericHealthValue) {
          final numero = valor.numericValue.toDouble();
          if (numero > 0) valores.add(numero);
        }
      }
      return valores;
    } catch (_) {
      return const [];
    }
  }

  Future<double?> obtenerUltimoValor(HealthDataType tipo, Duration ventana) async {
    final valores = await obtenerValoresRecientes(tipo, ventana);
    if (valores.isEmpty) return null;
    return valores.last;
  }

  Future<double?> obtenerPromedio(HealthDataType tipo, Duration ventana) async {
    final valores = await obtenerValoresRecientes(tipo, ventana);
    if (valores.isEmpty) return null;
    final suma = valores.reduce((a, b) => a + b);
    return suma / valores.length;
  }
}
