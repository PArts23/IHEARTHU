import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:iheart/nucleo/constantes.dart';

class ServicioConectividad {
  static final ServicioConectividad instancia = ServicioConectividad._interno();

  final ValueNotifier<bool> enLinea = ValueNotifier<bool>(true);
  Timer? _temporizador;
  int _suscriptores = 0;

  ServicioConectividad._interno();

  Future<bool> verificarAhora() async {
    try {
      final resultado = await InternetAddress.lookup(Constantes.hostBackend)
          .timeout(const Duration(seconds: 5));
      final conectado = resultado.isNotEmpty && resultado.first.rawAddress.isNotEmpty;
      enLinea.value = conectado;
      return conectado;
    } on SocketException {
      enLinea.value = false;
      return false;
    } on TimeoutException {
      enLinea.value = false;
      return false;
    } catch (_) {
      enLinea.value = false;
      return false;
    }
  }

  void suscribir() {
    _suscriptores++;
    if (_temporizador != null) return;
    verificarAhora();
    _temporizador = Timer.periodic(const Duration(seconds: 8), (_) => verificarAhora());
  }

  void cancelarSuscripcion() {
    _suscriptores = _suscriptores > 0 ? _suscriptores - 1 : 0;
    if (_suscriptores == 0) {
      _temporizador?.cancel();
      _temporizador = null;
    }
  }
}
