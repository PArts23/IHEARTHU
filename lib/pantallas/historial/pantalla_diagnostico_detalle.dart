import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/widgets/tabla_comparativa_sesiones.dart';

class PantallaDiagnosticoDetalle extends StatelessWidget {
  final int diagnosticoId;

  const PantallaDiagnosticoDetalle({super.key, required this.diagnosticoId});

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<ProveedorEstado>().historial;
    final indiceActual = historial.indexWhere((elemento) => elemento['diagnostico_id'] == diagnosticoId);
    final actual = indiceActual != -1 ? historial[indiceActual] : null;
    final anterior = indiceActual != -1 && indiceActual + 1 < historial.length ? historial[indiceActual + 1] : null;

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Detalle de diagnóstico'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            const Text(
              'Comparativa de sesiones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 8),
            const Text(
              'Métricas fisiológicas de esta sesión frente a la sesión inmediatamente anterior.',
              style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
            ),
            const SizedBox(height: 24),
            if (actual == null)
              const Center(child: Text('No se encontraron registros clínicos.'))
            else
              TablaComparativaSesiones(ultima: actual, penultima: anterior),
            const SizedBox(height: 24),
            const Text(
              Constantes.avisoLegalRiesgo,
              style: TextStyle(fontSize: 12, color: TemaApp.rojoError, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Todos los diagnósticos se calculan mediante inferencia local en su dispositivo. Ninguno de estos datos médicos se envía al exterior.',
              style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        indiceSeleccionado: 2,
        alCambiarFila: (indice) => context.irAPestana(indice),
      ),
    );
  }
}
