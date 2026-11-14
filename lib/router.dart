import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/pantallas/auth/pantalla_login.dart';
import 'package:iheart/pantallas/auth/pantalla_registro.dart';
import 'package:iheart/pantallas/auth/pantalla_recuperar.dart';
import 'package:iheart/pantallas/auth/pantalla_restablecer.dart';
import 'package:iheart/pantallas/inicio/pantalla_inicio.dart';
import 'package:iheart/pantallas/evaluar/pantalla_calibracion.dart';
import 'package:iheart/pantallas/evaluar/pantalla_cuestionario.dart';
import 'package:iheart/pantallas/evaluar/pantalla_resultado.dart';
import 'package:iheart/pantallas/historial/pantalla_diagnostico_detalle.dart';
import 'package:iheart/pantallas/historial/pantalla_mis_diagnosticos.dart';
import 'package:iheart/pantallas/ajustes/pantalla_health_connect.dart';
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
        return PantallaInicio(indiceInicial: indiceInicial, marcaNavegacion: state.uri.queryParameters['n']);
      },
    ),
    GoRoute(
      path: '/cuestionario',
      builder: (context, state) => const PantallaCuestionario(),
    ),
    GoRoute(
      path: '/resultado',
      builder: (context, state) {
        final extra = state.extra;
        final datos = extra is Map<String, Object?> ? extra : <String, Object?>{};
        return PantallaResultado(datos: DatosResultado.desdeMapa(datos));
      },
    ),
    GoRoute(
      path: '/diagnosticos',
      builder: (context, state) => const PantallaMisDiagnosticos(),
    ),
    GoRoute(
      path: '/health_connect',
      builder: (context, state) => const PantallaHealthConnect(),
    ),
    GoRoute(
      path: '/diagnostico_detalle',
      builder: (context, state) {
        final extra = state.extra;
        final valor = extra is Map<String, Object?> ? extra['diagnosticoId'] : null;
        return PantallaDiagnosticoDetalle(diagnosticoId: valor is int ? valor : 0);
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
