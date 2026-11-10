import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iheart/widgets/tarjeta_riesgo.dart';

void main() {
  testWidgets('La ausencia de evaluación no muestra riesgo bajo ni cero', (
    probador,
  ) async {
    await probador.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TarjetaRiesgo(
            porcentajeRiesgo: null,
            nivelRiesgo: 'sin evaluación',
          ),
        ),
      ),
    );
    expect(find.text('SIN EVALUACIÓN'), findsOneWidget);
    expect(find.text('0.0 %'), findsNothing);
    expect(find.text('BAJO'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Un resultado real de cero conserva su porcentaje', (
    probador,
  ) async {
    await probador.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TarjetaRiesgo(porcentajeRiesgo: 0, nivelRiesgo: 'bajo'),
        ),
      ),
    );
    expect(find.text('0.0 %'), findsOneWidget);
    expect(find.text('BAJO'), findsOneWidget);
    expect(find.text('SIN EVALUACIÓN'), findsNothing);
  });
}
