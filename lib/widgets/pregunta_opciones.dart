import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class OpcionPregunta<T> {
  final String etiqueta;
  final T valor;

  const OpcionPregunta({required this.etiqueta, required this.valor});
}

class PreguntaOpciones<T> extends StatelessWidget {
  final String pregunta;
  final List<OpcionPregunta<T>> opciones;
  final T? seleccion;
  final ValueChanged<T>? alSeleccionar;
  final bool habilitada;
  final bool mostrarPendiente;
  final String? ayuda;

  const PreguntaOpciones({
    super.key,
    required this.pregunta,
    required this.opciones,
    required this.seleccion,
    required this.alSeleccionar,
    this.habilitada = true,
    this.mostrarPendiente = false,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    final pendiente = mostrarPendiente && habilitada && seleccion == null;
    final textoAyuda = ayuda;
    return Opacity(
      opacity: habilitada ? 1 : 0.45,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pendiente ? TemaApp.rojoError : Colors.transparent, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pregunta,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TemaApp.textoOscuro),
            ),
            if (textoAyuda != null) ...[
              const SizedBox(height: 4),
              Text(textoAyuda, style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opciones.map((opcion) {
                final seleccionada = seleccion == opcion.valor;
                return ChoiceChip(
                  label: Text(opcion.etiqueta),
                  selected: seleccionada,
                  selectedColor: TemaApp.rojoPrimario,
                  backgroundColor: TemaApp.grisSuperficie,
                  labelStyle: TextStyle(
                    color: seleccionada ? TemaApp.blancoFondo : TemaApp.textoOscuro,
                    fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                  ),
                  showCheckmark: false,
                  onSelected: habilitada && alSeleccionar != null
                      ? (_) => alSeleccionar?.call(opcion.valor)
                      : null,
                );
              }).toList(),
            ),
            if (pendiente) ...[
              const SizedBox(height: 6),
              const Text('Respuesta requerida', style: TextStyle(fontSize: 12, color: TemaApp.rojoError)),
            ],
          ],
        ),
      ),
    );
  }
}
