import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:iheart/datos/repositorio_perfil.dart';
import 'package:iheart/nucleo/constantes.dart';

class SinDatosReporteException implements Exception {
  @override
  String toString() => Constantes.mensajeSinDatosReporte;
}

class GeneradorReportePdf {
  static const PdfColor _colorPrimario = PdfColor.fromInt(0xFF7B1624);

  String _fecha(Object? valor) {
    if (valor is! String) return '-';
    final fecha = DateTime.tryParse(valor);
    if (fecha == null) return valor;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  String _numero(Object? valor, String unidad, {double factor = 1, int decimales = 0}) {
    if (valor is! num) return '-';
    return '${(valor * factor).toStringAsFixed(decimales)}$unidad';
  }

  String _texto(Object? valor) => valor is String && valor.isNotEmpty ? valor : '-';

  pw.Widget _encabezado(PerfilPaciente? perfil) {
    final ahora = DateTime.now().toIso8601String();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'I HEAR(TH) U - Reporte de historial de diagnósticos',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Paciente: ${perfil?.nombreCompleto ?? '-'}'),
        pw.Text('DNI: ${perfil?.numeroDni ?? '-'}    Edad: ${perfil?.edad?.toString() ?? '-'}    Sexo: ${perfil?.sexo ?? '-'}'),
        pw.Text('Peso: ${_numero(perfil?.pesoKg, ' kg', decimales: 1)}    Altura: ${_numero(perfil?.alturaM, ' m', decimales: 2)}    IMC: ${_numero(perfil?.imc, '', decimales: 1)}'),
        pw.Text('Generado: ${_fecha(ahora)}'),
        pw.SizedBox(height: 16),
      ],
    );
  }

  pw.Widget _tabla(List<Map<String, Object?>> historial) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _colorPrimario),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.center,
      headers: const ['Fecha', 'Frec. cardíaca', 'SpO2', 'HRV', 'Riesgo CAD', 'Nivel', 'Resultado'],
      data: historial
          .map((fila) => [
                _fecha(fila['creado_en']),
                _numero(fila['bpm_promedio'], ' bpm'),
                _numero(fila['spo2_promedio'], '%'),
                _numero(fila['hrv_ms'], ' ms'),
                _numero(fila['probabilidad_cad'], '%', factor: 100, decimales: 1),
                _texto(fila['nivel_riesgo']),
                _texto(fila['etiqueta_prediccion']),
              ])
          .toList(),
    );
  }

  Future<Uint8List> generar({
    required PerfilPaciente? perfil,
    required List<Map<String, Object?>> historial,
  }) async {
    if (historial.isEmpty) throw SinDatosReporteException();
    final documento = pw.Document(title: 'Historial de diagnósticos', author: 'I HEAR(TH) U');
    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (contexto) => [
          _encabezado(perfil),
          pw.Text('Total de diagnósticos: ${historial.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _tabla(historial),
          pw.SizedBox(height: 24),
          pw.Text(Constantes.avisoLegalRiesgo, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
    return documento.save();
  }

  Future<void> generarYCompartir({
    required PerfilPaciente? perfil,
    required List<Map<String, Object?>> historial,
  }) async {
    final bytes = await generar(perfil: perfil, historial: historial);
    final ahora = DateTime.now();
    final nombre = 'iheart_historial_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: nombre);
  }
}
