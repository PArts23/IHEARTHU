import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/grafico_ppg.dart';
import 'package:iheart/widgets/tarjeta_riesgo.dart';
import 'package:iheart/widgets/tarjeta_signo_vital.dart';

class VistaPanelPrincipal extends StatelessWidget {
  final VoidCallback alIniciarDiagnostico;

  const VistaPanelPrincipal({super.key, required this.alIniciarDiagnostico});

  static String obtenerIniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'P';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    final apellido = partes.length >= 3 ? partes[partes.length - 2] : partes.last;
    return '${partes.first[0]}${apellido[0]}'.toUpperCase();
  }

  double? _leerNumero(Map<String, Object?>? mapa, String clave) {
    final valor = mapa?[clave];
    return valor is num ? valor.toDouble() : null;
  }

  (String, Color) _estadoFrecuencia(double? bpm) {
    if (bpm == null) return ('Sin lectura', TemaApp.textoSecundario);
    if (bpm < 60) return ('Baja', TemaApp.amarilloAlerta);
    if (bpm > 100) return ('Elevada', TemaApp.rojoError);
    return ('Normal', TemaApp.verdeExito);
  }

  (String, Color) _estadoSaturacion(double? spo2) {
    if (spo2 == null) return ('Sin lectura', TemaApp.textoSecundario);
    if (spo2 < 90) return ('Crítica', TemaApp.rojoError);
    if (spo2 < 95) return ('Baja', TemaApp.amarilloAlerta);
    return ('Normal', TemaApp.verdeExito);
  }

  Widget _construirCabecera(String iniciales, String saludoNombre) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: TemaApp.rojoPrimario,
          child: Text(iniciales, style: const TextStyle(color: TemaApp.blancoFondo, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $saludoNombre',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
              ),
              const Text(
                '¿Cómo se siente su corazón hoy?',
                style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirSignosVitales(Map<String, Object?>? ultimo) {
    final bpm = _leerNumero(ultimo, 'bpm_promedio');
    final spo2 = _leerNumero(ultimo, 'spo2_promedio');
    final (estadoBpm, colorBpm) = _estadoFrecuencia(bpm);
    final (estadoSpo2, colorSpo2) = _estadoSaturacion(spo2);
    return Row(
      children: [
        Expanded(
          child: TarjetaSignoVital(
            icono: Icons.favorite,
            titulo: 'Frecuencia cardíaca',
            valor: bpm != null ? '${bpm.toStringAsFixed(0)} bpm' : '— bpm',
            estado: estadoBpm,
            colorEstado: colorBpm,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TarjetaSignoVital(
            icono: Icons.opacity,
            titulo: 'Saturación de oxígeno (SpO2)',
            valor: spo2 != null ? '${spo2.toStringAsFixed(0)}%' : '—%',
            estado: estadoSpo2,
            colorEstado: colorSpo2,
          ),
        ),
      ],
    );
  }

  Widget _construirGraficoYAccion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ritmo cardíaco (últimas 6 horas)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaApp.grisSuperficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TemaApp.grisBorde),
          ),
          child: const GraficoPPG(interactivo: false),
        ),
        const SizedBox(height: 32),
        BotonPrimario(texto: 'INICIAR NUEVO DIAGNÓSTICO', alPresionar: alIniciarDiagnostico),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final perfil = estado.perfil;
    final ultimo = estado.historial.isNotEmpty ? estado.historial.first : null;
    final nombre = perfil?.nombreCompleto ?? '';
    final saludo = nombre.trim().isNotEmpty ? nombre.trim().split(RegExp(r'\s+')).first : 'Paciente';
    final creado = ultimo?['creado_en'];
    final etiqueta = ultimo?['etiqueta_prediccion'];
    final nivel = ultimo?['nivel_riesgo'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabecera(obtenerIniciales(nombre), saludo),
          const SizedBox(height: 24),
          TarjetaRiesgo(
            porcentajeRiesgo: _leerNumero(ultimo, 'probabilidad_cad'),
            nivelRiesgo: nivel is String ? nivel : 'sin evaluación',
            etiqueta: etiqueta is String ? etiqueta : null,
            actualizadoEn: creado is String ? DateTime.tryParse(creado) : null,
          ),
          const SizedBox(height: 24),
          _construirSignosVitales(ultimo),
          const SizedBox(height: 24),
          _construirGraficoYAccion(),
        ],
      ),
    );
  }
}
