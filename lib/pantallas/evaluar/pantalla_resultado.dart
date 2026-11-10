import 'package:flutter/material.dart';
import 'package:iheart/modelo/generador_recomendaciones.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/widgets/boton_primario.dart';

class DatosResultado {
  final double probabilidad;
  final String nivelRiesgo;
  final String nombrePaciente;
  final double? frecuenciaPromedio;
  final double? variabilidadMs;
  final List<Recomendacion> recomendaciones;

  const DatosResultado({
    required this.probabilidad,
    required this.nivelRiesgo,
    required this.nombrePaciente,
    required this.frecuenciaPromedio,
    required this.variabilidadMs,
    required this.recomendaciones,
  });

  factory DatosResultado.desdeMapa(Map<String, Object?> mapa) {
    final probabilidad = mapa['probabilidad'];
    final riesgo = mapa['riesgo'];
    final nombre = mapa['nombre'];
    final frecuencia = mapa['frecuencia_promedio'];
    final variabilidad = mapa['hrv'];
    final recomendaciones = mapa['recomendaciones'];
    return DatosResultado(
      probabilidad: probabilidad is num ? probabilidad.toDouble() : 0,
      nivelRiesgo: riesgo is String ? riesgo : 'bajo',
      nombrePaciente: nombre is String ? nombre : 'Paciente',
      frecuenciaPromedio: frecuencia is num ? frecuencia.toDouble() : null,
      variabilidadMs: variabilidad is num ? variabilidad.toDouble() : null,
      recomendaciones: recomendaciones is List<Recomendacion> ? recomendaciones : const [],
    );
  }
}

class PantallaResultado extends StatelessWidget {
  final DatosResultado datos;

  const PantallaResultado({super.key, required this.datos});

  String get _iniciales {
    final partes = datos.nombrePaciente.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'P';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    final apellido = partes.length >= 3 ? partes[partes.length - 2] : partes.last;
    return '${partes.first[0]}${apellido[0]}'.toUpperCase();
  }

  Color _colorRiesgo() {
    switch (datos.nivelRiesgo) {
      case 'moderado':
        return TemaApp.amarilloAlerta;
      case 'alto':
        return TemaApp.rojoClaro;
      case 'crítico':
        return TemaApp.rojoError;
      default:
        return TemaApp.verdeExito;
    }
  }

  String _textoNivel() {
    final nivel = datos.nivelRiesgo;
    if (nivel.isEmpty) return 'Bajo';
    return '${nivel[0].toUpperCase()}${nivel.substring(1)}';
  }

  IconData _iconoRecomendacion(String tipo) {
    switch (tipo) {
      case 'diet':
        return Icons.restaurant_menu;
      case 'doctor':
        return Icons.local_hospital;
      case 'exercise':
        return Icons.directions_run;
      default:
        return Icons.info_outline;
    }
  }

  Widget _construirEncabezado() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: TemaApp.rojoPrimario,
          child: Text(
            _iniciales,
            style: const TextStyle(color: TemaApp.blancoFondo, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Informe de salud: ${datos.nombrePaciente}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
          ),
        ),
      ],
    );
  }

  Widget _construirMetrica(IconData icono, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.grisSuperficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: Row(
        children: [
          Icon(icono, color: TemaApp.rojoPrimario, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                const SizedBox(height: 4),
                Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRiesgo() {
    final color = _colorRiesgo();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('RIESGO', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${(datos.probabilidad * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Text(
              _textoNivel(),
              style: const TextStyle(color: TemaApp.blancoFondo, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPanelMetricas() {
    final frecuencia = datos.frecuenciaPromedio;
    final variabilidad = datos.variabilidadMs;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _construirMetrica(
                  Icons.bolt,
                  'HRV',
                  variabilidad != null ? '${variabilidad.toStringAsFixed(0)} ms' : '-- ms',
                ),
                const SizedBox(height: 12),
                _construirMetrica(
                  Icons.favorite,
                  'Avg HR',
                  frecuencia != null ? '${frecuencia.toStringAsFixed(0)} bpm' : '-- bpm',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _construirRiesgo()),
        ],
      ),
    );
  }

  Widget _construirRecomendaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recomendaciones proactivas:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
        ),
        const SizedBox(height: 12),
        ...datos.recomendaciones.map(
          (recomendacion) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TemaApp.rojoPrimario.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconoRecomendacion(recomendacion.icono), color: TemaApp.rojoPrimario, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(recomendacion.texto, style: const TextStyle(fontSize: 14, color: TemaApp.textoOscuro)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirAvisoLegal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.rojoError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TemaApp.rojoError.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: TemaApp.rojoError),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              Constantes.avisoLegalRiesgo,
              style: TextStyle(fontSize: 12, color: TemaApp.rojoError, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.irAPestana(0);
      },
      child: Scaffold(
        backgroundColor: TemaApp.blancoFondo,
        appBar: AppBar(
          title: const Text('Diagnóstico'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.irAPestana(0),
          ),
          backgroundColor: TemaApp.rojoPrimario,
          foregroundColor: TemaApp.blancoFondo,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _construirEncabezado(),
                const SizedBox(height: 24),
                _construirPanelMetricas(),
                const SizedBox(height: 24),
                _construirRecomendaciones(),
                const SizedBox(height: 24),
                _construirAvisoLegal(),
                const SizedBox(height: 32),
                BotonPrimario(texto: 'Volver al Inicio', alPresionar: () => context.irAPestana(0)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
