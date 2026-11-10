import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/red/servicio_biometrico.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/widgets/grafico_ppg.dart';

class TarjetaPpgEnVivo extends StatefulWidget {
  const TarjetaPpgEnVivo({super.key});

  @override
  State<TarjetaPpgEnVivo> createState() => _TarjetaPpgEnVivoState();
}

class _TarjetaPpgEnVivoState extends State<TarjetaPpgEnVivo> {
  final ServicioWearable _wearable = ServicioWearable.instancia;
  Timer? _temporizador;
  double? _bpm;
  double? _spo2;

  @override
  void initState() {
    super.initState();
    _leerSignos();
    _temporizador = Timer.periodic(const Duration(seconds: 15), (_) => _leerSignos());
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _leerSignos() async {
    final servicio = ServicioBiometrico.instancia;
    final bpm = await servicio.obtenerUltimoValor(HealthDataType.HEART_RATE, const Duration(hours: 1));
    final spo2 = await servicio.obtenerUltimoValor(HealthDataType.BLOOD_OXYGEN, const Duration(hours: 24));
    if (!mounted) return;
    setState(() {
      _bpm = bpm;
      _spo2 = spo2 != null && spo2 <= 1 ? spo2 * 100 : spo2;
    });
  }

  bool _estaDesconectado(EstadoWearable estado) {
    return estado == EstadoWearable.desconectado ||
        estado == EstadoWearable.reconectando ||
        estado == EstadoWearable.bluetoothApagado;
  }

  String _textoEstado(EstadoWearable estado) {
    switch (estado) {
      case EstadoWearable.reconectando:
        return '— Sensor desconectado';
      case EstadoWearable.desconectado:
      case EstadoWearable.bluetoothApagado:
        return '— Sensor desconectado';
      case EstadoWearable.conectado:
      case EstadoWearable.sinVincular:
        return '— en vivo';
    }
  }

  Widget _construirLectura(String titulo, String valor) {
    return Expanded(
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro)),
        ],
      ),
    );
  }

  Widget _construirContenido(EstadoWearable estado) {
    final desconectado = _estaDesconectado(estado);
    final bpm = _bpm;
    final spo2 = _spo2;
    final color = desconectado ? TemaApp.rojoError : TemaApp.verdeExito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(desconectado ? Icons.sensors_off : Icons.sensors, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fotopletismografía (PPG) ${_textoEstado(estado)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: desconectado ? color : TemaApp.textoOscuro),
              ),
            ),
          ],
        ),
        if (estado == EstadoWearable.reconectando) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.rojoPrimario)),
              SizedBox(width: 8),
              Text('Reconectando automáticamente con el wearable...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            _construirLectura('Frecuencia', !desconectado && bpm != null ? '${bpm.toStringAsFixed(0)} bpm' : '-- bpm'),
            _construirLectura('SpO2', !desconectado && spo2 != null ? '${spo2.toStringAsFixed(0)}%' : '--%'),
          ],
        ),
        const SizedBox(height: 12),
        if (desconectado)
          const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Monitoreo en pausa hasta que el sensor se reconecte.',
                style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
              ),
            ),
          )
        else
          const GraficoPPG(interactivo: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.grisSuperficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: ValueListenableBuilder<EstadoWearable>(
        valueListenable: _wearable.estado,
        builder: (contexto, estado, _) => _construirContenido(estado),
      ),
    );
  }
}
