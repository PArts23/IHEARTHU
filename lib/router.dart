import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/pantallas/auth/pantalla_login.dart';
import 'package:iheart/pantallas/auth/pantalla_registro.dart';
import 'package:iheart/pantallas/auth/pantalla_recuperar.dart';
import 'package:iheart/pantallas/auth/pantalla_restablecer.dart';
import 'package:iheart/pantallas/inicio/pantalla_inicio.dart';
import 'package:iheart/pantallas/evaluar/pantalla_calibracion.dart';
import 'package:iheart/pantallas/evaluar/pantalla_cuestionario.dart';
import 'package:iheart/pantallas/evaluar/pantalla_resultado.dart';
import 'package:iheart/pantallas/historial/pantalla_diagnostico_detalle.dart';
import 'package:iheart/pantallas/ajustes/pantalla_iot.dart';
import 'package:iheart/pantallas/ajustes/pantalla_modelo_fl.dart';

final GoRouter rutasApp = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext contexto, GoRouterState estado) async {
    const almacenamiento = FlutterSecureStorage();
    final token = await almacenamiento.read(key: Constantes.claveTokenJwt);
    final estaAutenticado = token != null;

    final rutaActual = estado.matchedLocation;

    if (rutaActual == '/restablecer') {
      return null;
    }

    if (!estaAutenticado) {
      if (rutaActual == '/login' || rutaActual == '/registro' || rutaActual == '/recuperar') {
        return null;
      }
      return '/login';
    }

    if (rutaActual == '/login' || rutaActual == '/registro' || rutaActual == '/recuperar' || rutaActual == '/') {
      final modeloListo = InferenciaLocal.instancia.inicializado;
      if (!modeloListo) {
        return '/calibracion';
      }
      return '/inicio';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const PantallaLogin(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const PantallaRegistro(),
    ),
    GoRoute(
      path: '/recuperar',
      builder: (context, state) => const PantallaRecuperar(),
    ),
    GoRoute(
      path: '/restablecer',
      builder: (context, state) => PantallaRestablecer(
        correoInicial: state.uri.queryParameters['correo'] ?? '',
        codigoInicial: state.uri.queryParameters['codigo'] ?? '',
      ),
    ),
    GoRoute(
      path: '/calibracion',
      builder: (context, state) => const PantallaCalibracion(),
    ),
    GoRoute(
      path: '/inicio',
      builder: (context, state) {
        final indiceInicial = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return PantallaInicio(indiceInicial: indiceInicial);
      },
    ),
    GoRoute(
      path: '/cuestionario',
      builder: (context, state) => const PantallaCuestionario(),
    ),
    GoRoute(
      path: '/resultado',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final probabilidad = (extra['probabilidad'] as num? ?? 0.0).toDouble();
        final riesgo = extra['riesgo'] as String? ?? 'bajo';
        return PantallaResultado(
          probabilidadRiesgo: probabilidad,
          nivelRiesgo: riesgo,
        );
      },
    ),
    GoRoute(
      path: '/diagnostico_detalle',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final diagnosticoId = extra['diagnosticoId'] as int? ?? 0;
        return PantallaDiagnosticoDetalle(diagnosticoId: diagnosticoId);
      },
    ),
    GoRoute(
      path: '/iot',
      builder: (context, state) => const PantallaIoT(),
    ),
    GoRoute(
      path: '/modelo_fl',
      builder: (context, state) => const PantallaModeloFL(),
    ),
  ],
);
