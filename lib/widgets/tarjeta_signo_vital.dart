import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class TarjetaSignoVital extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String? estado;
  final Color colorEstado;

  const TarjetaSignoVital({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.estado,
    this.colorEstado = TemaApp.textoSecundario,
  });

  @override
  Widget build(BuildContext context) {
    final textoEstado = estado;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: TemaApp.rojoPrimario, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro)),
          if (textoEstado != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: colorEstado, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  textoEstado,
                  style: TextStyle(fontSize: 12, color: colorEstado, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
