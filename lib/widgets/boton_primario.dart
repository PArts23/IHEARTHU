import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class BotonPrimario extends StatelessWidget {
  final String texto;
  final VoidCallback? alPresionar;
  final bool cargando;

  const BotonPrimario({
    super.key,
    required this.texto,
    this.alPresionar,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (cargando || alPresionar == null) ? null : alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: TemaApp.rojoPrimario,
          foregroundColor: TemaApp.blancoFondo,
          disabledBackgroundColor: TemaApp.rojoPrimario.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        child: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: TemaApp.blancoFondo,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
