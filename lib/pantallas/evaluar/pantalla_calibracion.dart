import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/red/servicio_biometrico.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';

enum EstadoPasoCalibracion { pendiente, enCurso, completado, error }

enum FalloCalibracion { ninguno, perfilIncompleto, sensorDesconectado, modeloNoDisponible }

class PantallaCalibracion extends StatefulWidget {
  const PantallaCalibracion({super.key});

  @override
  State<PantallaCalibracion> createState() => _PantallaCalibracionState();
}

class _PantallaCalibracionState extends State<PantallaCalibracion> {
  static const List<String> _mensajesInformativos = [
    'Su teléfono está analizando sus datos cardíacos en reposo.',
    'Este proceso calibra los umbrales personalizados del algoritmo para un diagnóstico preciso sin comprometer sus datos.',
    'Antes de activar predicciones automáticas y alertas, requerimos primero recolectar sus datos.',
    'Este perfil base es único y solo usted tiene acceso.',
  ];

  double _progreso = 0;
  bool _calibrando = false;
  FalloCalibracion _fallo = FalloCalibracion.ninguno;
  EstadoPasoCalibracion _pasoPerfil = EstadoPasoCalibracion.pendiente;
  EstadoPasoCalibracion _pasoModelo = EstadoPasoCalibracion.pendiente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarCalibracion());
  }

  void _actualizar(VoidCallback cambio) {
    if (mounted) setState(cambio);
  }

  Future<void> _esperar(int milisegundos) => Future<void>.delayed(Duration(milliseconds: milisegundos));

  Future<bool> _sensorDisponible() async {
    final wearable = ServicioWearable.instancia;
    if (!wearable.bluetoothEncendido) return false;
    if (wearable.estado.value == EstadoWearable.conectado) return true;
    final lecturas = await ServicioBiometrico.instancia.obtenerValoresRecientes(
      HealthDataType.HEART_RATE,
      const Duration(hours: 24),
    );
    return lecturas.isNotEmpty;
  }

  Future<void> _iniciarCalibracion() async {
    if (_calibrando) return;
    final estado = context.read<ProveedorEstado>();
    _actualizar(() {
      _calibrando = true;
      _fallo = FalloCalibracion.ninguno;
      _progreso = 0.05;
      _pasoPerfil = EstadoPasoCalibracion.enCurso;
      _pasoModelo = EstadoPasoCalibracion.pendiente;
    });
    await _esperar(700);
    if (!estado.perfilCompleto) {
      _detener(FalloCalibracion.perfilIncompleto);
      return;
    }
    _actualizar(() {
      _pasoPerfil = EstadoPasoCalibracion.completado;
      _pasoModelo = EstadoPasoCalibracion.enCurso;
      _progreso = 0.3;
    });
    await _esperar(600);
    if (!await _sensorDisponible()) {
      _detener(FalloCalibracion.sensorDesconectado);
      return;
    }
    _actualizar(() => _progreso = 0.55);
    if (!await _asegurarModelo(estado)) return;
    _actualizar(() => _progreso = 0.85);
    await _esperar(900);
    await estado.marcarPerfilCalibrado(true);
    _actualizar(() {
      _progreso = 1;
      _pasoModelo = EstadoPasoCalibracion.completado;
      _calibrando = false;
    });
    await _esperar(1200);
    if (mounted) {
      context.mostrarMensajeExito('Calibración completada correctamente');
      context.irAPestana(1);
    }
  }

  Future<bool> _asegurarModelo(ProveedorEstado estado) async {
    if (InferenciaLocal.instancia.inicializado) return true;
    try {
      if (await InferenciaLocal.instancia.inicializar()) return true;
      await estado.sincronizarModelo();
      if (InferenciaLocal.instancia.inicializado) return true;
      _detener(FalloCalibracion.modeloNoDisponible);
      return false;
    } catch (_) {
      _detener(FalloCalibracion.modeloNoDisponible);
      return false;
    }
  }

  void _detener(FalloCalibracion fallo) {
    _actualizar(() {
      _calibrando = false;
      _fallo = fallo;
      if (fallo == FalloCalibracion.perfilIncompleto) {
        _pasoPerfil = EstadoPasoCalibracion.error;
      } else {
        _pasoModelo = EstadoPasoCalibracion.error;
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_mensajeFallo()),
        backgroundColor: TemaApp.rojoError,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar calibración',
          textColor: TemaApp.blancoFondo,
          onPressed: _iniciarCalibracion,
        ),
      ),
    );
  }

  String _mensajeFallo() {
    switch (_fallo) {
      case FalloCalibracion.perfilIncompleto:
        return Constantes.mensajePerfilIncompleto;
      case FalloCalibracion.sensorDesconectado:
        return Constantes.mensajeVerifiqueDispositivo;
      case FalloCalibracion.modeloNoDisponible:
        return 'No se pudo obtener el modelo federado. Verifique su conexión a internet.';
      case FalloCalibracion.ninguno:
        return '';
    }
  }

  Widget _construirAnillo() {
    final color = _fallo == FalloCalibracion.ninguno ? TemaApp.rojoPrimario : TemaApp.amarilloAlerta;
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: _progreso,
              strokeWidth: 10,
              backgroundColor: TemaApp.grisSuperficie,
              color: color,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progreso * 100).toInt()}%',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
                  ),
                  const Text('Completado', style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirItemInformativo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: TemaApp.rojoPrimario, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: TemaApp.textoOscuro))),
        ],
      ),
    );
  }

  Widget _construirPaso(String titulo, EstadoPasoCalibracion paso, String mensajeError) {
    final completado = paso == EstadoPasoCalibracion.completado;
    final error = paso == EstadoPasoCalibracion.error;
    final subtitulo = switch (paso) {
      EstadoPasoCalibracion.completado => 'Completado',
      EstadoPasoCalibracion.error => mensajeError,
      EstadoPasoCalibracion.enCurso => 'En proceso...',
      EstadoPasoCalibracion.pendiente => 'Pendiente',
    };
    final color = completado ? TemaApp.verdeExito : (error ? TemaApp.rojoError : TemaApp.textoSecundario);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: paso == EstadoPasoCalibracion.enCurso
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: TemaApp.rojoPrimario),
            )
          : Icon(
              completado ? Icons.check_circle : (error ? Icons.error : Icons.radio_button_unchecked),
              color: color,
            ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitulo, style: TextStyle(color: color)),
    );
  }

  Widget _construirAcciones() {
    if (_calibrando || _fallo == FalloCalibracion.ninguno) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _mensajeFallo(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: TemaApp.rojoError, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        BotonPrimario(texto: 'Reintentar', alPresionar: _iniciarCalibracion),
        if (_fallo == FalloCalibracion.perfilIncompleto) ...[
          const SizedBox(height: 12),
          BotonSecundario(texto: 'Completar mi perfil', alPresionar: () => context.irAPestana(3)),
        ],
        if (_fallo == FalloCalibracion.sensorDesconectado) ...[
          const SizedBox(height: 12),
          BotonSecundario(texto: 'Verificar conexión de wearable', alPresionar: () => context.push('/iot')),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Calibración del Perfil Local'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.irAPestana(0)),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            const Text(
              'Iniciando calibración del Perfil Local',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 24),
            _construirAnillo(),
            const SizedBox(height: 12),
            const Text(
              'Solo tardará unos momentos...',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaApp.textoSecundario),
            ),
            const SizedBox(height: 24),
            ..._mensajesInformativos.map(_construirItemInformativo),
            const SizedBox(height: 16),
            _construirPaso('Perfil completado', _pasoPerfil, Constantes.mensajePerfilIncompleto),
            _construirPaso('Calibración del modelo FL', _pasoModelo, _mensajeFallo()),
            const SizedBox(height: 24),
            _construirAcciones(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
