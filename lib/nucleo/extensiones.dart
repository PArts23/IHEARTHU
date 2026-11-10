import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/tema.dart';

extension ContextExtension on BuildContext {
  ThemeData get tema => Theme.of(this);
  TextTheme get textoTema => tema.textTheme;

  void mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: TemaApp.verdeExito,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: TemaApp.rojoError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void irAPestana(int indice) {
    go('/inicio?tab=$indice&n=${DateTime.now().microsecondsSinceEpoch}');
  }
}
