import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:iheart/datos/repositorio_dispositivos.dart';

enum EstadoWearable { sinVincular, conectado, desconectado, reconectando, bluetoothApagado }

class BluetoothApagadoException implements Exception {
  final String mensaje = 'Activar Bluetooth para buscar dispositivos IoT';

  @override
  String toString() => mensaje;
}

class ServicioWearable {
  static final ServicioWearable instancia = ServicioWearable._interno();

  final RepositorioDispositivos _repositorio = RepositorioDispositivos();
  final ValueNotifier<EstadoWearable> estado = ValueNotifier<EstadoWearable>(EstadoWearable.sinVincular);
  final ValueNotifier<DispositivoIot?> dispositivo = ValueNotifier<DispositivoIot?>(null);
  final StreamController<String> _avisos = StreamController<String>.broadcast();

  StreamSubscription<BluetoothAdapterState>? _suscripcionAdaptador;
  StreamSubscription<BluetoothConnectionState>? _suscripcionConexion;
  BluetoothDevice? _dispositivoBle;
  bool _inicializado = false;
  bool _desconexionIntencional = false;

  ServicioWearable._interno();

  Stream<String> get avisos => _avisos.stream;
  Stream<List<ScanResult>> get resultadosBusqueda => FlutterBluePlus.scanResults;
  Stream<bool> get buscando => FlutterBluePlus.isScanning;

  bool get bluetoothEncendido => FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;

  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;
    try {
      dispositivo.value = await _repositorio.obtenerDispositivoActivo();
      _suscripcionAdaptador = FlutterBluePlus.adapterState.listen(_alCambiarAdaptador);
    } catch (error) {
      debugPrint('No se pudo inicializar el wearable: $error');
    }
  }

  void _alCambiarAdaptador(BluetoothAdapterState estadoAdaptador) {
    if (estadoAdaptador != BluetoothAdapterState.on) {
      if (estado.value == EstadoWearable.conectado) {
        _avisos.add('El sensor se desconectó: el Bluetooth está apagado.');
      }
      estado.value = EstadoWearable.bluetoothApagado;
      return;
    }
    final vinculado = dispositivo.value;
    if (vinculado == null || vinculado.direccionMac == null) {
      estado.value = EstadoWearable.sinVincular;
      return;
    }
    _monitorear(vinculado);
  }

  void _monitorear(DispositivoIot vinculado) {
    final mac = vinculado.direccionMac;
    if (mac == null) return;
    final ble = BluetoothDevice.fromId(mac);
    _dispositivoBle = ble;
    _suscripcionConexion?.cancel();
    _suscripcionConexion = ble.connectionState.listen(_alCambiarConexion);
    _reconectar();
  }

  Future<void> _alCambiarConexion(BluetoothConnectionState estadoConexion) async {
    if (estadoConexion == BluetoothConnectionState.connected) {
      final anterior = estado.value;
      estado.value = EstadoWearable.conectado;
      if (anterior == EstadoWearable.reconectando || anterior == EstadoWearable.desconectado) {
        _avisos.add('Sensor reconectado. Monitoreo en vivo reanudado.');
      }
      await _leerInformacionDispositivo();
      return;
    }
    if (estadoConexion != BluetoothConnectionState.disconnected) return;
    if (_desconexionIntencional || dispositivo.value == null) return;
    if (!bluetoothEncendido) {
      estado.value = EstadoWearable.bluetoothApagado;
      return;
    }
    if (estado.value == EstadoWearable.conectado) {
      _avisos.add('El sensor se desconectó. Intentando reconectar automáticamente...');
    }
    estado.value = EstadoWearable.reconectando;
    await _reconectar();
  }

  Future<void> _reconectar() async {
    final ble = _dispositivoBle;
    if (ble == null || !bluetoothEncendido) return;
    if (estado.value != EstadoWearable.conectado) {
      estado.value = EstadoWearable.reconectando;
    }
    try {
      await ble.connect(autoConnect: true, mtu: null);
    } catch (error) {
      debugPrint('Reconexión pendiente: $error');
    }
  }

  Future<void> buscarDispositivos() async {
    if (!bluetoothEncendido) {
      throw BluetoothApagadoException();
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
    } catch (error) {
      throw StateError('No se pudo iniciar la búsqueda de dispositivos: $error');
    }
  }

  Future<void> detenerBusqueda() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> encenderBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    } catch (error) {
      throw StateError('No se pudo activar el Bluetooth: $error');
    }
  }

  Future<DispositivoIot> vincular(ScanResult resultado) async {
    await detenerBusqueda();
    final ble = resultado.device;
    final nombre = _nombreVisible(resultado);
    try {
      _desconexionIntencional = true;
      await _dispositivoBle?.disconnect();
      await ble.connect(timeout: const Duration(seconds: 20));
      if (Platform.isAndroid) {
        await ble.createBond();
      }
      final nuevo = DispositivoIot(
        nombre: nombre,
        marca: _inferirMarca(nombre),
        modelo: nombre,
        direccionMac: ble.remoteId.str,
        tipo: 'smartwatch',
        ultimaSincronizacion: DateTime.now().toIso8601String(),
      );
      await _repositorio.guardarDispositivoActivo(nuevo);
      dispositivo.value = nuevo;
      _desconexionIntencional = false;
      _monitorear(nuevo);
      await _leerInformacionDispositivo();
      return dispositivo.value ?? nuevo;
    } catch (error) {
      _desconexionIntencional = false;
      throw StateError('No se pudo completar el emparejamiento: $error');
    }
  }

  Future<void> desvincular() async {
    try {
      _desconexionIntencional = true;
      await _suscripcionConexion?.cancel();
      await _dispositivoBle?.disconnect();
      await _repositorio.desvincularTodos();
    } catch (error) {
      debugPrint('Error al desvincular: $error');
    } finally {
      _dispositivoBle = null;
      dispositivo.value = null;
      estado.value = bluetoothEncendido ? EstadoWearable.sinVincular : EstadoWearable.bluetoothApagado;
      _desconexionIntencional = false;
    }
  }

  Future<void> reintentarConexion() => _reconectar();

  String _nombreVisible(ScanResult resultado) {
    final anunciado = resultado.advertisementData.advName;
    if (anunciado.isNotEmpty) return anunciado;
    final plataforma = resultado.device.platformName;
    if (plataforma.isNotEmpty) return plataforma;
    return 'Dispositivo ${resultado.device.remoteId.str}';
  }

  String? _inferirMarca(String nombre) {
    final texto = nombre.toLowerCase();
    if (texto.contains('xiaomi') || texto.contains('mi band') || texto.contains('smart band')) return 'Xiaomi';
    if (texto.contains('polar')) return 'Polar';
    if (texto.contains('galaxy')) return 'Samsung';
    return null;
  }

  bool _coincideUuid(Guid uuid, String corto) {
    final texto = uuid.str.toLowerCase();
    return texto == corto || texto.startsWith('0000$corto-');
  }

  Future<void> _leerInformacionDispositivo() async {
    final ble = _dispositivoBle;
    final actual = dispositivo.value;
    if (ble == null || actual == null || !ble.isConnected) return;
    try {
      int? bateria;
      String? firmware;
      final servicios = await ble.discoverServices();
      for (final servicio in servicios) {
        for (final caracteristica in servicio.characteristics) {
          if (_coincideUuid(servicio.uuid, '180f') && _coincideUuid(caracteristica.uuid, '2a19')) {
            final valor = await caracteristica.read();
            if (valor.isNotEmpty) bateria = valor.first;
          }
          if (_coincideUuid(servicio.uuid, '180a') && _coincideUuid(caracteristica.uuid, '2a26')) {
            final valor = await caracteristica.read();
            if (valor.isNotEmpty) firmware = String.fromCharCodes(valor);
          }
        }
      }
      final actualizado = actual.copiarCon(
        firmware: firmware,
        bateriaPorcentaje: bateria,
        ultimaSincronizacion: DateTime.now().toIso8601String(),
      );
      dispositivo.value = actualizado;
      await _repositorio.actualizarEstado(actualizado);
    } catch (error) {
      debugPrint('No se pudo leer la información del wearable: $error');
    }
  }

  Future<void> liberar() async {
    await _suscripcionAdaptador?.cancel();
    await _suscripcionConexion?.cancel();
  }
}
