import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iheart/datos/repositorio_dispositivos.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';

class PantallaIoT extends StatefulWidget {
  const PantallaIoT({super.key});

  @override
  State<PantallaIoT> createState() => _PantallaIoTState();
}

class _PantallaIoTState extends State<PantallaIoT> {
  final ServicioWearable _wearable = ServicioWearable.instancia;
  bool _busquedaIniciada = false;
  String? _vinculandoId;

  @override
  void dispose() {
    _wearable.detenerBusqueda();
    super.dispose();
  }

  Future<bool> _solicitarPermisosBluetooth() async {
    try {
      final resultados = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
      return resultados.values.every((estado) => estado.isGranted || estado.isLimited);
    } catch (_) {
      return true;
    }
  }

  Future<void> _mostrarDialogoBluetooth() async {
    final activar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        icon: const Icon(Icons.bluetooth_disabled, color: TemaApp.rojoError),
        title: const Text('Bluetooth desactivado'),
        content: const Text('Activar Bluetooth para buscar dispositivos IoT'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Activar', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (activar != true) return;
    try {
      await _wearable.encenderBluetooth();
    } catch (e) {
      if (mounted) context.mostrarMensajeError(e.toString());
    }
  }

  Future<void> _buscar() async {
    if (!await _solicitarPermisosBluetooth()) {
      if (mounted) context.mostrarMensajeError('Conceda los permisos de Bluetooth para buscar dispositivos.');
      return;
    }
    try {
      setState(() => _busquedaIniciada = true);
      await _wearable.buscarDispositivos();
    } on BluetoothApagadoException {
      if (!mounted) return;
      setState(() => _busquedaIniciada = false);
      await _mostrarDialogoBluetooth();
    } catch (e) {
      if (mounted) context.mostrarMensajeError(e.toString());
    }
  }

  Future<void> _vincular(ScanResult resultado) async {
    final nombre = resultado.advertisementData.advName.isNotEmpty
        ? resultado.advertisementData.advName
        : resultado.device.platformName;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Vincular dispositivo'),
        content: Text(
          '¿Desea emparejar "${nombre.isEmpty ? resultado.device.remoteId.str : nombre}"?\n\n'
          'Si el dispositivo lo solicita, confirme el PIN de emparejamiento que se mostrará a continuación.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Vincular', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _vinculandoId = resultado.device.remoteId.str);
    try {
      final dispositivo = await _wearable.vincular(resultado);
      if (mounted) context.mostrarMensajeExito('${dispositivo.nombre} vinculado correctamente');
    } catch (e) {
      if (mounted) context.mostrarMensajeError(e.toString());
    } finally {
      if (mounted) setState(() => _vinculandoId = null);
    }
  }

  (String, Color) _textoEstado(EstadoWearable estado) {
    switch (estado) {
      case EstadoWearable.conectado:
        return ('Conectado', TemaApp.verdeExito);
      case EstadoWearable.reconectando:
        return ('Reconectando...', TemaApp.amarilloAlerta);
      case EstadoWearable.desconectado:
        return ('Desconectado', TemaApp.rojoError);
      case EstadoWearable.bluetoothApagado:
        return ('Desconectado / Bluetooth apagado', TemaApp.rojoError);
      case EstadoWearable.sinVincular:
        return ('Sin vincular', TemaApp.textoSecundario);
    }
  }

  Widget _dato(String titulo, String valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 11, color: TemaApp.textoSecundario)),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _construirTarjetaActual(DispositivoIot? dispositivo, EstadoWearable estado) {
    final (texto, color) = _textoEstado(dispositivo == null && estado != EstadoWearable.bluetoothApagado
        ? EstadoWearable.sinVincular
        : estado);
    final conectado = estado == EstadoWearable.conectado;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.watch, color: conectado ? TemaApp.rojoPrimario : TemaApp.textoSecundario, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dispositivo?.nombre ?? 'Ningún wearable vinculado',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (dispositivo != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _dato('Batería', dispositivo.bateriaPorcentaje != null ? '${dispositivo.bateriaPorcentaje}%' : '--'),
                _dato('Firmware', dispositivo.firmware ?? '--'),
                _dato('Señal PPG', conectado ? 'Buena' : '--'),
                _dato('Procesamiento', 'Local'),
              ],
            ),
            const SizedBox(height: 16),
            _construirAccionesActual(conectado),
          ],
        ],
      ),
    );
  }

  Widget _construirAccionesActual(bool conectado) {
    return Row(
      children: [
        if (!conectado) ...[
          Expanded(
            child: BotonPrimario(
              texto: 'Reconectar',
              alPresionar: () async {
                if (!_wearable.bluetoothEncendido) {
                  await _mostrarDialogoBluetooth();
                  return;
                }
                await _wearable.reintentarConexion();
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: BotonSecundario(texto: 'Desvincular', alPresionar: _wearable.desvincular)),
      ],
    );
  }

  Widget _construirResultado(ScanResult resultado) {
    final nombre = resultado.advertisementData.advName.isNotEmpty
        ? resultado.advertisementData.advName
        : (resultado.device.platformName.isNotEmpty ? resultado.device.platformName : 'Dispositivo sin nombre');
    final vinculando = _vinculandoId == resultado.device.remoteId.str;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: TemaApp.grisBorde),
      ),
      child: ListTile(
        leading: const Icon(Icons.watch_outlined, color: TemaApp.rojoPrimario),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('MAC: ${resultado.device.remoteId.str}\nSeñal (RSSI): ${resultado.rssi} dBm'),
        isThreeLine: true,
        trailing: vinculando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.rojoPrimario))
            : const Icon(Icons.link, color: TemaApp.rojoPrimario),
        onTap: _vinculandoId == null ? () => _vincular(resultado) : null,
      ),
    );
  }

  Widget _construirListaRango() {
    return StreamBuilder<bool>(
      stream: _wearable.buscando,
      initialData: false,
      builder: (contexto, instantaneaBusqueda) {
        final buscando = instantaneaBusqueda.data ?? false;
        return StreamBuilder<List<ScanResult>>(
          stream: _wearable.resultadosBusqueda,
          initialData: const [],
          builder: (contextoLista, instantanea) {
            final resultados = (instantanea.data ?? const <ScanResult>[]).toList()
              ..sort((a, b) => b.rssi.compareTo(a.rssi));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (buscando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.rojoPrimario)),
                        SizedBox(width: 12),
                        Text('Buscando dispositivos...'),
                      ],
                    ),
                  ),
                if (!buscando && _busquedaIniciada && resultados.isEmpty)
                  const Text('No se encontraron dispositivos. Verifique que su wearable esté en modo visible.'),
                if (!_busquedaIniciada)
                  const Text(
                    'Presione "BUSCAR DISPOSITIVOS (IoT)" para detectar wearables cercanos.',
                    style: TextStyle(color: TemaApp.textoSecundario),
                  ),
                ...resultados.map(_construirResultado),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirSeccionNuevo(EstadoWearable estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Añadir nuevo Wearable (IoT)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (estado == EstadoWearable.bluetoothApagado)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TemaApp.amarilloAlerta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('El Bluetooth está apagado. Actívelo para buscar y conectar wearables.'),
          ),
        BotonPrimario(texto: 'BUSCAR DISPOSITIVOS (IoT)', alPresionar: _buscar),
        const SizedBox(height: 24),
        const Text('Dispositivos en Rango', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _construirListaRango(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Vinculación IoT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.irAPestana(4),
        ),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: ValueListenableBuilder<DispositivoIot?>(
        valueListenable: _wearable.dispositivo,
        builder: (contexto, dispositivo, _) => ValueListenableBuilder<EstadoWearable>(
          valueListenable: _wearable.estado,
          builder: (contextoEstado, estado, _) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _construirTarjetaActual(dispositivo, estado),
              const SizedBox(height: 24),
              _construirSeccionNuevo(estado),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        indiceSeleccionado: 4,
        alCambiarFila: (indice) => context.irAPestana(indice),
      ),
    );
  }
}
