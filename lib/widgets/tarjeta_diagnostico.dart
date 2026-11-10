import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/widgets/tabla_comparativa_sesiones.dart';

class TarjetaDiagnostico extends StatelessWidget {
  final Map<String, Object?> diagnostico;
  final VoidCallback? alPresionar;

  const TarjetaDiagnostico({super.key, required this.diagnostico, this.alPresionar});

  Color _color(String nivel) {
    switch (nivel) {
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

  @override
  Widget build(BuildContext context) {
    final nivelValor = diagnostico['nivel_riesgo'];
    final nivel = nivelValor is String ? nivelValor : 'bajo';
    final tipoValor = diagnostico['sesion_tipo'];
    final tipo = tipoValor is String && tipoValor == 'reposo' ? 'Monitoreo en reposo (wearable)' : 'Ingreso manual';
    final color = _color(nivel);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TemaApp.grisBorde),
      ),
      child: ListTile(
        onTap: alPresionar,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: TemaApp.rojoPrimario.withValues(alpha: 0.08),
          child: const Icon(Icons.favorite, color: TemaApp.rojoPrimario),
        ),
        title: Text(
          TablaComparativaSesiones.formatearFecha(diagnostico['creado_en']),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$tipo · ${TablaComparativaSesiones.formatearValor(diagnostico, 'bpm_promedio', ' bpm')}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              TablaComparativaSesiones.formatearValor(diagnostico, 'probabilidad_cad', ' %', factor: 100),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(nivel.toUpperCase(), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
