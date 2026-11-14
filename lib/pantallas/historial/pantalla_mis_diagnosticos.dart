import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/widgets/tabla_comparativa_sesiones.dart';
import 'package:iheart/widgets/tarjeta_diagnostico.dart';

class PantallaMisDiagnosticos extends StatefulWidget {
  const PantallaMisDiagnosticos({super.key});

  @override
  State<PantallaMisDiagnosticos> createState() => _PantallaMisDiagnosticosState();
}

class _PantallaMisDiagnosticosState extends State<PantallaMisDiagnosticos> {
  final _controladorBusqueda = TextEditingController();
  DateTimeRange? _rango;
  String _tipo = 'todos';

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  bool _cumpleFiltros(Map<String, Object?> diagnostico) {
    final creado = diagnostico['creado_en'];
    final fecha = creado is String ? DateTime.tryParse(creado) : null;
    final rango = _rango;
    if (rango != null) {
      if (fecha == null) return false;
      final fin = rango.end.add(const Duration(days: 1));
      if (fecha.isBefore(rango.start) || !fecha.isBefore(fin)) return false;
    }
    final tipo = diagnostico['sesion_tipo'];
    if (_tipo == 'reposo' && tipo != 'reposo') return false;
    if (_tipo == 'manual' && tipo == 'reposo') return false;
    final busqueda = _controladorBusqueda.text.trim().toLowerCase();
    if (busqueda.isEmpty) return true;
    final texto = [
      TablaComparativaSesiones.formatearFecha(creado),
      diagnostico['nivel_riesgo'],
      diagnostico['etiqueta_prediccion'],
    ].whereType<String>().join(' ').toLowerCase();
    return texto.contains(busqueda);
  }

  Future<void> _seleccionarRango() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 5),
      lastDate: ahora,
      initialDateRange: _rango,
      helpText: 'Filtrar por rango de fechas',
    );
    if (rango != null && mounted) setState(() => _rango = rango);
  }

  String _textoRango() {
    final rango = _rango;
    if (rango == null) return 'Rango de fechas';
    String formato(DateTime fecha) => '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';
    return '${formato(rango.start)} - ${formato(rango.end)}';
  }

  Widget _construirFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controladorBusqueda,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar por fecha, nivel de riesgo o resultado',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: TemaApp.grisSuperficie,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(_textoRango()),
              onPressed: _seleccionarRango,
            ),
            if (_rango != null)
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _rango = null)),
            ...const {'todos': 'Todos', 'reposo': 'Wearable', 'manual': 'Manual'}.entries.map(
                  (entrada) => ChoiceChip(
                    label: Text(entrada.value),
                    selected: _tipo == entrada.key,
                    selectedColor: TemaApp.rojoPrimario.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _tipo = entrada.key),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<ProveedorEstado>().historial;
    final filtrados = historial.where(_cumpleFiltros).toList();
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Mis diagnósticos'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.irAPestana(0)),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _construirFiltros(),
          const SizedBox(height: 16),
          Text(
            '${filtrados.length} de ${historial.length} diagnósticos',
            style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
          ),
          const SizedBox(height: 8),
          if (historial.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(Constantes.mensajeSinRegistrosMonitoreo, textAlign: TextAlign.center),
            )
          else if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No hay diagnósticos que coincidan con los filtros.', textAlign: TextAlign.center),
            )
          else
            ...filtrados.map(
              (diagnostico) => TarjetaDiagnostico(
                diagnostico: diagnostico,
                alPresionar: () {
                  final id = diagnostico['diagnostico_id'];
                  if (id is int) context.push('/diagnostico_detalle', extra: <String, Object?>{'diagnosticoId': id});
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BarraNavegacion(
        indiceSeleccionado: 2,
        alCambiarFila: (indice) => context.irAPestana(indice),
      ),
    );
  }
}
