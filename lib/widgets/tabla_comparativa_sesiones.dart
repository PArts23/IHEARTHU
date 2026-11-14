import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class TablaComparativaSesiones extends StatelessWidget {
  final Map<String, Object?> ultima;
  final Map<String, Object?>? penultima;

  const TablaComparativaSesiones({super.key, required this.ultima, this.penultima});

  static String formatearFecha(Object? valor) {
    if (valor is! String) return '--';
    final fecha = DateTime.tryParse(valor);
    if (fecha == null) return valor.split('T').first;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  static String formatearValor(Map<String, Object?>? mapa, String clave, String unidad, {double factor = 1}) {
    final valor = mapa?[clave];
    if (valor is! num) return '--';
    final decimales = factor == 100 ? 1 : 0;
    return '${(valor * factor).toStringAsFixed(decimales)}$unidad';
  }

  TableRow _fila(String parametro, String anterior, String actual, {bool cabecera = false}) {
    final estilo = TextStyle(fontWeight: cabecera ? FontWeight.bold : FontWeight.normal, fontSize: 13);
    return TableRow(
      decoration: cabecera ? const BoxDecoration(color: TemaApp.grisSuperficie) : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(parametro, style: estilo.copyWith(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(anterior, style: estilo, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            actual,
            style: estilo.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final previa = penultima;
    return Table(
      border: TableBorder.all(color: TemaApp.grisBorde, width: 1, borderRadius: BorderRadius.circular(8)),
      columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _fila('Parámetro', 'Penúltima sesión', 'Última sesión', cabecera: true),
        _fila(
          'Fecha',
          previa == null ? 'Sin registro previo' : formatearFecha(previa['creado_en']),
          formatearFecha(ultima['creado_en']),
        ),
        _fila('Frec. cardíaca', formatearValor(previa, 'bpm_promedio', ' bpm'), formatearValor(ultima, 'bpm_promedio', ' bpm')),
        _fila('SpO2', formatearValor(previa, 'spo2_promedio', '%'), formatearValor(ultima, 'spo2_promedio', '%')),
        _fila('HRV', formatearValor(previa, 'hrv_ms', ' ms'), formatearValor(ultima, 'hrv_ms', ' ms')),
        _fila(
          'Riesgo CAD',
          formatearValor(previa, 'probabilidad_cad', ' %', factor: 100),
          formatearValor(ultima, 'probabilidad_cad', ' %', factor: 100),
        ),
      ],
    );
  }
}
