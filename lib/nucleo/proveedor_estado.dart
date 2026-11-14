import 'package:flutter/material.dart';
import 'package:iheart/datos/repositorio_perfil.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/datos/repositorio_diagnosticos.dart';
import 'package:iheart/datos/repositorio_modelo.dart';
import 'package:iheart/datos/repositorio_preferencias.dart';
import 'package:iheart/modelo/generador_recomendaciones.dart';
import 'package:iheart/nucleo/validadores.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/red/servicio_auth.dart';
import 'package:iheart/red/servicio_modelo.dart';
import 'package:iheart/red/servicio_federado.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/modelo/fedavg_local.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProveedorEstado extends ChangeNotifier {
  final RepositorioPerfil _repoPerfil = RepositorioPerfil();
  final RepositorioSesiones _repoSesiones = RepositorioSesiones();
  final RepositorioDiagnosticos _repoDiagnosticos = RepositorioDiagnosticos();
  final RepositorioModelo _repoModelo = RepositorioModelo();
  final RepositorioPreferencias _repoPreferencias = RepositorioPreferencias();

  final ServicioAuth _servicioAuth = ServicioAuth();
  final ServicioModelo _servicioModelo = ServicioModelo();
  final ServicioFederado _servicioFederado = ServicioFederado();

  PerfilPaciente? _perfil;
  EstadoModeloFl? _estadoModelo;
  List<SesionMonitoreo> _sesiones = [];
  List<Map<String, Object?>> _historial = [];
  bool _cargando = false;
  bool _perfilCalibrado = false;
  bool _notificacionesActivas = true;

  PerfilPaciente? get perfil => _perfil;
  bool get perfilCalibrado => _perfilCalibrado && InferenciaLocal.instancia.inicializado;
  bool get notificacionesActivas => _notificacionesActivas;

  String get descripcionEstadoModelo {
    if (perfilCalibrado && _notificacionesActivas) {
      return 'El sistema está calibrado correctamente y las notificaciones de emergencia están activadas.';
    }
    if (perfilCalibrado) {
      return 'El sistema está calibrado correctamente. Las notificaciones de emergencia están desactivadas.';
    }
    return 'El perfil local aún no está calibrado. Inicie un diagnóstico para calibrarlo.';
  }

  bool get perfilCompleto {
    final actual = _perfil;
    if (actual == null) return false;
    return actual.nombreCompleto.trim().isNotEmpty &&
        Validadores.esEdadValida(actual.edad) &&
        actual.sexo != null &&
        Validadores.esPesoValido(actual.pesoKg) &&
        Validadores.esAlturaValida(actual.alturaM);
  }
  EstadoModeloFl? get estadoModelo => _estadoModelo;
  List<SesionMonitoreo> get sesiones => _sesiones;
  List<Map<String, Object?>> get historial => _historial;
  bool get cargando => _cargando;

  Future<void> inicializarApp() async {
    _cargando = true;
    notifyListeners();

    try {
      _perfil = await _repoPerfil.obtenerPerfil();
      _estadoModelo = await _repoModelo.obtenerEstadoFL();
      _perfilCalibrado = await _repoPreferencias.obtenerPerfilCalibrado();
      _notificacionesActivas = await _repoPreferencias.obtenerNotificacionesActivas();
      await InferenciaLocal.instancia.inicializar();
      await ServicioWearable.instancia.inicializar();
      
      if (_perfil != null) {
        await cargarDatosLocales();
      }
    } catch (_) {}

    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarDatosLocales() async {
    _sesiones = await _repoSesiones.obtenerSesionesRecientes(limite: 10);
    _historial = await _repoDiagnosticos.obtenerHistorialCompleto();
    _estadoModelo = await _repoModelo.obtenerEstadoFL();
    notifyListeners();
  }

  Future<void> iniciarSesion(String correo, String contrasena) async {
    _cargando = true;
    notifyListeners();

    try {
      final resultado = await _servicioAuth.iniciarSesion(correo, contrasena);
      final perfilLocal = await _repoPerfil.obtenerPerfil();
      final perfilPrevio = perfilLocal != null &&
              perfilLocal.correo.toLowerCase() == resultado.correo.toLowerCase()
          ? perfilLocal
          : null;
      final mismoPaciente = perfilPrevio != null;
      final nuevoPerfil = PerfilPaciente(
        id: resultado.usuarioId,
        nombreCompleto: resultado.nombreCompleto,
        numeroDni: resultado.numeroDni,
        correo: resultado.correo,
        edad: perfilPrevio?.edad,
        sexo: perfilPrevio?.sexo,
        pesoKg: perfilPrevio?.pesoKg,
        alturaM: perfilPrevio?.alturaM,
        ciudad: 'Lima',
        pais: 'Perú',
        tokenJwt: resultado.token,
        tokenExpiraEn: resultado.expiraEn,
        versionModeloLocal: perfilPrevio?.versionModeloLocal ?? 0,
      );
      if (!mismoPaciente) {
        await _repoPerfil.eliminarPerfiles();
        await _repoPreferencias.limpiar();
        _perfilCalibrado = false;
      }

      await _repoPerfil.guardarPerfil(nuevoPerfil);
      _perfil = await _repoPerfil.obtenerPerfil();
      await cargarDatosLocales();
      try {
        await InferenciaLocal.instancia.inicializar();
      } catch (_) {}
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrarUsuario({
    required String nombreCompleto,
    required String numeroDni,
    required String correo,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      await _servicioAuth.registrarUsuario(
        nombreCompleto: nombreCompleto,
        numeroDni: numeroDni,
        correo: correo,
        contrasena: contrasena,
        confirmarContrasena: confirmarContrasena,
      );
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> marcarPerfilCalibrado(bool calibrado) async {
    _perfilCalibrado = calibrado;
    await _repoPreferencias.guardarPerfilCalibrado(calibrado);
    notifyListeners();
  }

  Future<void> cambiarNotificaciones(bool activas) async {
    _notificacionesActivas = activas;
    await _repoPreferencias.guardarNotificacionesActivas(activas);
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _repoPerfil.cerrarSesion();
    _perfil = null;
    _sesiones = [];
    _historial = [];
    InferenciaLocal.instancia.desactivar();
    notifyListeners();
  }

  Future<void> actualizarPerfil(PerfilPaciente perfilActualizado) async {
    _cargando = true;
    notifyListeners();

    try {
      await _repoPerfil.guardarPerfil(perfilActualizado);
      _perfil = await _repoPerfil.obtenerPerfil();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> sincronizarModelo() async {
    _cargando = true;
    notifyListeners();

    try {
      final versionServidor = await _servicioModelo.obtenerVersionModelo();
      final versionLocal = _estadoModelo?.versionLocal ?? 0;

      await _repoModelo.registrarSincronizacion(
        tipo: 'version_check',
        exitoso: true,
        versionAntes: versionLocal,
        versionDespues: versionLocal,
        detalle: 'Verificación de versión del modelo. Servidor: $versionServidor. Local: $versionLocal',
      );

      if (versionServidor > versionLocal) {
        final bytesModelo = await _servicioModelo.descargarModeloTflite();
        final directorio = await getApplicationDocumentsDirectory();
        
        final archivoModelo = File('${directorio.path}/modelo.tflite');
        await archivoModelo.writeAsBytes(bytesModelo);

        final archivoScaler = File('${directorio.path}/scaler.json');
        await archivoScaler.writeAsString('{"mean": [58.549586776859506, 74.53719008264463, 164.88842975206612, 0.5785123966942148, 27.417379253166768, 0.3181818181818182, 0.5743801652892562, 0.1859504132231405, 0.0371900826446281, 0.1652892561983471, 0.7107438016528925, 0.02066115702479339, 0.02066115702479339, 0.028925619834710745, 0.028925619834710745, 0.004132231404958678, 0.3677685950413223, 129.39256198347107, 74.95454545454545, 0.0371900826446281, 0.5413223140495868, 0.4297520661157025, 0.30991735537190085, 0.045454545454545456, 2.2644628099173554, 2.0, 2.3595041322314048, 0.14049586776859505, 1.3264462809917354, 0.23553719008264462, 2.2724256072162596, 0.45867768595041325], "std": [10.296012418896602, 12.360321295079165, 9.10861630121454, 0.4937973304558554, 4.031338497737248, 0.4657704893618, 0.49443664003747084, 0.389066648590295, 0.18922732465876582, 0.3714414058552768, 0.4534170817965353, 0.14224722709139265, 0.14224722709139262, 0.16759751893118444, 0.16759751893118455, 0.06414948221595089, 0.48219794228372037, 18.253235489439522, 8.935142800174152, 0.18922732465876574, 0.4982895406905382, 0.4950406324585761, 0.4624592827603177, 0.20829889522526585, 1.0346764179873877, 0.8381404052084444, 1.1422088584970806, 0.3591952696214991, 0.5029283824343865, 0.4243340926329362, 0.4932155462306114, 0.49828954069053844]}');

        final inicializado = await InferenciaLocal.instancia.inicializar();
        if (inicializado) {
          final nuevoEstado = EstadoModeloFl(
            id: 1,
            versionServidor: versionServidor,
            versionLocal: versionServidor,
            rutaModeloTflite: archivoModelo.path,
            rondaActual: _estadoModelo?.rondaActual ?? 0,
            ultimaSincronizacion: DateTime.now().toIso8601String(),
            pesosPendientes: _estadoModelo?.pesosPendientes ?? false,
            entrenamientoLocalCompletado: _estadoModelo?.entrenamientoLocalCompletado ?? false,
            accuracyLocal: _estadoModelo?.accuracyLocal,
            actualizadoEn: DateTime.now().toIso8601String(),
          );

          await _repoModelo.actualizarEstadoFL(nuevoEstado);
          _estadoModelo = nuevoEstado;

          await _repoModelo.registrarSincronizacion(
            tipo: 'descarga_modelo',
            exitoso: true,
            versionAntes: versionLocal,
            versionDespues: versionServidor,
            detalle: 'Modelo TFLite versión $versionServidor descargado con éxito.',
          );
        }
      }
    } catch (e) {
      await _repoModelo.registrarSincronizacion(
        tipo: 'descarga_modelo',
        exitoso: false,
        versionAntes: _estadoModelo?.versionLocal ?? 0,
        versionDespues: _estadoModelo?.versionLocal ?? 0,
        detalle: 'Error descargando modelo: ${e.toString()}',
      );
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> entrenarYSubirPesosFL() async {
    _cargando = true;
    notifyListeners();

    try {
      final pesos = await FedAvgLocal.instancia.entrenarModeloLocal();
      
      if (_perfil != null && _estadoModelo != null) {
        await _servicioFederado.subirPesosFL(
          idCliente: _perfil!.id,
          ronda: _estadoModelo!.rondaActual + 1,
          numeroMuestras: 5,
          pesos: pesos,
        );

        await FedAvgLocal.instancia.limpiarPesosLocales();
        
        await _repoModelo.registrarSincronizacion(
          tipo: 'subida_pesos',
          exitoso: true,
          detalle: 'Pesos federados de la ronda ${_estadoModelo!.rondaActual + 1} subidos con éxito.',
        );
      }
    } catch (e) {
      await _repoModelo.registrarSincronizacion(
        tipo: 'subida_pesos',
        exitoso: false,
        detalle: 'Error subiendo pesos federados: ${e.toString()}',
      );
      rethrow;
    } finally {
      await cargarDatosLocales();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrarNuevaSesion(SesionMonitoreo sesion) async {
    await _repoSesiones.guardarSesion(sesion);
    await cargarDatosLocales();
  }

  Future<int> registrarDiagnosticoCompleto({
    required SesionMonitoreo sesion,
    required CuestionarioClinico cuestionario,
    required double probabilidad,
    required String riesgo,
    required String etiqueta,
    required String featuresJson,
  }) async {
    final sesionId = await _repoSesiones.guardarSesion(sesion);
    
    final nuevoCuestionario = CuestionarioClinico(
      idSesionMonitoreo: sesionId,
      tieneDiabetes: cuestionario.tieneDiabetes,
      tieneHipertension: cuestionario.tieneHipertension,
      tieneAccidenteCerebrovascular: cuestionario.tieneAccidenteCerebrovascular,
      tieneInsuficienciaRenal: cuestionario.tieneInsuficienciaRenal,
      tieneEnfermedadRespiratoria: cuestionario.tieneEnfermedadRespiratoria,
      tieneEnfermedadTiroidea: cuestionario.tieneEnfermedadTiroidea,
      tieneInsuficienciaCardiaca: cuestionario.tieneInsuficienciaCardiaca,
      tieneDislipidemia: cuestionario.tieneDislipidemia,
      tieneObesidad: cuestionario.tieneObesidad,
      esFumadorActivo: cuestionario.esFumadorActivo,
      esExFumador: cuestionario.esExFumador,
      antecedenteFamiliarCad: cuestionario.antecedenteFamiliarCad,
      presentaEdema: cuestionario.presentaEdema,
      presentaDolorPecho: cuestionario.presentaDolorPecho,
      frecuenciaDolorPecho: cuestionario.frecuenciaDolorPecho,
      clasificacionDolor: cuestionario.clasificacionDolor,
      tipoDolor: cuestionario.tipoDolor,
      esfuerzoFisicoReciente: cuestionario.esfuerzoFisicoReciente,
      disnea: cuestionario.disnea,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final cuestionarioId = await _repoDiagnosticos.guardarCuestionario(nuevoCuestionario);

    final diagnostico = DiagnosticoClinico(
      idSesionMonitoreo: sesionId,
      idCuestionario: cuestionarioId,
      probabilidadCad: probabilidad,
      nivelRiesgo: riesgo,
      etiquetaPrediccion: etiqueta,
      versionModeloUsada: _estadoModelo?.versionLocal ?? 0,
      umbralAplicado: 0.5,
      inferenciaLocal: true,
      featuresJson: featuresJson,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final diagnosticoId = await _repoDiagnosticos.guardarDiagnostico(diagnostico);

    final recomendaciones = GeneradorRecomendaciones.generar(
      nivelRiesgo: riesgo,
      cuestionario: cuestionario,
    );
    for (final recomendacion in recomendaciones) {
      await _repoDiagnosticos.guardarRecomendacion(RecomendacionClinica(
        idDiagnostico: diagnosticoId,
        texto: recomendacion.texto,
        icono: recomendacion.icono,
        prioridad: recomendacion.prioridad,
        creadoEn: DateTime.now().toIso8601String(),
      ));
    }

    if (_notificacionesActivas && (riesgo == 'alto' || riesgo == 'crítico')) {
      await _repoModelo.guardarAlerta(AlertaCardiaca(
        tipo: 'riesgo_alto',
        mensaje: 'Se ha detectado un riesgo cardiovascular elevado ($riesgo). Recomendamos consultar con un médico.',
        valorDetectado: probabilidad,
        leida: false,
        creadoEn: DateTime.now().toIso8601String(),
      ));
    }

    await cargarDatosLocales();
    return diagnosticoId;
  }
}
