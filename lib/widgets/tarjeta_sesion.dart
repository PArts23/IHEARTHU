import 'package:flutter/material.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/nucleo/tema.dart';

class TarjetaSesion extends StatelessWidget {
  final SesionMonitoreo sesion;
  final VoidCallback? alPresionar;

  const TarjetaSesion({
    super.key,
    required this.sesion,
    this.alPresionar,
  });

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return '${texto[0].toUpperCase()}${texto.substring(1).replaceAll('_', ' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: alPresionar,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TemaApp.rojoPrimario.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: TemaApp.rojoPrimario,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizar(sesion.tipo),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TemaApp.textoOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sesion.iniciadoEn.split('T')[0],
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaApp.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (sesion.bpmPromedio != null)
                        Text(
                          '${sesion.bpmPromedio!.toStringAsFixed(0)} bpm',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TemaApp.textoOscuro,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (sesion.spo2Promedio != null)
                        Text(
                          'SpO2: ${sesion.spo2Promedio!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaApp.textoSecundario,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
