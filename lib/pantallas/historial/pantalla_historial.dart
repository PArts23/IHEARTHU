import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/reportes/generador_reporte_pdf.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/tabla_comparativa_sesiones.dart';
import 'package:iheart/widgets/tarjeta_diagnostico.dart';
import 'package:iheart/widgets/tarjeta_ppg_en_vivo.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  bool _exportando = false;

  Future<void> _exportarHistorial() async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Exportar historial'),
        content: const Text('¿Desea exportar su historial de diagnósticos en formato PDF?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Aceptar', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (aceptar != true || !mounted) return;

    final estado = context.read<ProveedorEstado>();
    if (estado.historial.isEmpty) {
      context.mostrarMensajeError(Constantes.mensajeSinDatosReporte);
      return;
    }
    setState(() => _exportando = true);
    try {
      await GeneradorReportePdf().generarYCompartir(perfil: estado.perfil, historial: estado.historial);
    } on SinDatosReporteException catch (error) {
      if (mounted) context.mostrarMensajeError(error.toString());
    } catch (error) {
      if (mounted) context.mostrarMensajeError('No se pudo generar el reporte PDF: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _abrirDetalle(Map<String, Object?> diagnostico) {
    final id = diagnostico['diagnostico_id'];
    if (id is int) {
      context.push('/diagnostico_detalle', extra: <String, Object?>{'diagnosticoId': id});
    }
  }

  Widget _construirEncabezadoSesiones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sesiones recientes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
        ),
        TextButton(
          onPressed: () => context.push('/diagnosticos'),
          child: const Text('Ver todas', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _construirEstadoVacio() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.grisSuperficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: TemaApp.textoSecundario),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Constantes.mensajeSinRegistrosMonitoreo,
                  style: TextStyle(color: TemaApp.textoOscuro, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Realice su primer diagnóstico desde la pestaña Evaluar.',
                  style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _construirSesiones(List<Map<String, Object?>> historial) {
    if (historial.isEmpty) return [_construirEstadoVacio()];
    return [
      TablaComparativaSesiones(ultima: historial.first, penultima: historial.length > 1 ? historial[1] : null),
      const SizedBox(height: 16),
      ...historial.take(4).map(
            (diagnostico) => TarjetaDiagnostico(
              diagnostico: diagnostico,
              alPresionar: () => _abrirDetalle(diagnostico),
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<ProveedorEstado>().historial;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TarjetaPpgEnVivo(),
          const SizedBox(height: 24),
          _construirEncabezadoSesiones(),
          const SizedBox(height: 8),
          ..._construirSesiones(historial),
          const SizedBox(height: 24),
          BotonPrimario(texto: 'EXPORTAR HISTORIAL', cargando: _exportando, alPresionar: _exportarHistorial),
          const SizedBox(height: 8),
          const Text(
            'Se generará un reporte PDF con su historial de diagnósticos para compartir o guardar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: TemaApp.textoSecundario),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
