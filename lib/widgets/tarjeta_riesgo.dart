import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class TarjetaRiesgo extends StatelessWidget {
  final double? porcentajeRiesgo;
  final String nivelRiesgo;
  final String? etiqueta;
  final DateTime? actualizadoEn;

  const TarjetaRiesgo({
    super.key,
    required this.porcentajeRiesgo,
    required this.nivelRiesgo,
    this.etiqueta,
    this.actualizadoEn,
  });

  String _textoTiempo(DateTime momento) {
    final diferencia = DateTime.now().difference(momento);
    if (diferencia.inMinutes < 1) return 'Actualizado hace instantes';
    if (diferencia.inHours < 1) return 'Actualizado hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'Actualizado hace ${diferencia.inHours} h';
    return 'Actualizado hace ${diferencia.inDays} d';
  }

  String _textoNivel() {
    if (nivelRiesgo.isEmpty) return '';
    return 'Riesgo ${nivelRiesgo.toLowerCase()}';
  }

  Color _obtenerColorRiesgo(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return TemaApp.verdeExito;
      case 'moderado':
        return TemaApp.amarilloAlerta;
      case 'alto':
        return TemaApp.rojoClaro;
      case 'crítico':
      case 'critico':
        return TemaApp.rojoError;
      default:
        return TemaApp.textoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riesgo = porcentajeRiesgo;
    final colorRiesgo = riesgo == null
        ? TemaApp.textoSecundario
        : _obtenerColorRiesgo(nivelRiesgo);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riesgo de enfermedad de arterias coronarias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TemaApp.textoOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riesgo == null ? '—' : '${(riesgo * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorRiesgo,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorRiesgo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riesgo == null ? 'SIN EVALUACIÓN' : (etiqueta ?? nivelRiesgo.toUpperCase()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorRiesgo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (riesgo == null)
            const Text(
              'Complete una evaluación para obtener una estimación.',
              style: TextStyle(color: TemaApp.textoSecundario),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: riesgo,
                minHeight: 12,
                backgroundColor: TemaApp.grisSuperficie,
                color: colorRiesgo,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_textoNivel(), style: TextStyle(fontSize: 12, color: colorRiesgo, fontWeight: FontWeight.w600)),
                if (actualizadoEn != null)
                  Text(
                    _textoTiempo(actualizadoEn!),
                    style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
