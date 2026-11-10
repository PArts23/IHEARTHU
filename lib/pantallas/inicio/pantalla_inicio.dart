import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/pantallas/inicio/vista_panel_principal.dart';
import 'package:iheart/pantallas/evaluar/pantalla_cuestionario.dart';
import 'package:iheart/pantallas/historial/pantalla_historial.dart';
import 'package:iheart/pantallas/perfil/pantalla_perfil.dart';
import 'package:iheart/pantallas/ajustes/pantalla_ajustes.dart';

class PantallaInicio extends StatefulWidget {
  final int indiceInicial;
  final String? marcaNavegacion;

  const PantallaInicio({super.key, this.indiceInicial = 0, this.marcaNavegacion});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  static const List<String> _titulos = [
    'I HEART',
    'Iniciar diagnóstico',
    'Historial médico',
    'Mi perfil',
    'Configuración',
  ];

  final GlobalKey<EstadoPantallaPerfil> _clavePerfil = GlobalKey<EstadoPantallaPerfil>();
  final List<int> _pilaPestanas = [];
  late int _indiceSeleccionado;
  StreamSubscription<String>? _suscripcionAvisos;

  @override
  void initState() {
    super.initState();
    _indiceSeleccionado = _normalizarIndice(widget.indiceInicial);
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarPermisosGenerales());
    _suscripcionAvisos = ServicioWearable.instancia.avisos.listen(_mostrarAvisoWearable);
  }

  @override
  void didUpdateWidget(covariant PantallaInicio anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.indiceInicial != widget.indiceInicial || anterior.marcaNavegacion != widget.marcaNavegacion) {
      setState(() => _indiceSeleccionado = _normalizarIndice(widget.indiceInicial));
    }
  }

  @override
  void dispose() {
    _suscripcionAvisos?.cancel();
    super.dispose();
  }

  int _normalizarIndice(int indice) => indice < 0 || indice > 4 ? 0 : indice;

  void _mostrarAvisoWearable(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: TemaApp.amarilloAlerta, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _solicitarPermisosGenerales() async {
    try {
      final notificaciones = context.read<ProveedorEstado>().notificacionesActivas;
      if (notificaciones) await Permission.notification.request();
      await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    } catch (_) {}
  }

  Future<bool> _puedeSalirDePestanaActual() async {
    if (_indiceSeleccionado != 3) return true;
    final estadoPerfil = _clavePerfil.currentState;
    if (estadoPerfil == null || !estadoPerfil.tieneCambiosSinGuardar) return true;
    final salir = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('¿Desea salir sin guardar los cambios?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Sí', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (salir == true) {
      estadoPerfil.descartarCambios();
      return true;
    }
    return false;
  }

  Future<void> _cambiarPestana(int indice) async {
    if (indice == _indiceSeleccionado) return;
    if (!await _puedeSalirDePestanaActual()) return;
    if (!mounted) return;
    setState(() {
      _pilaPestanas.remove(_indiceSeleccionado);
      _pilaPestanas.add(_indiceSeleccionado);
      _indiceSeleccionado = indice;
    });
  }

  Future<void> _volver() async {
    if (!await _puedeSalirDePestanaActual()) return;
    if (!mounted) return;
    setState(() {
      int anterior = 0;
      while (_pilaPestanas.isNotEmpty) {
        final candidato = _pilaPestanas.removeLast();
        if (candidato != _indiceSeleccionado) {
          anterior = candidato;
          break;
        }
      }
      _indiceSeleccionado = anterior;
    });
  }

  void _iniciarDiagnostico() {
    final estado = context.read<ProveedorEstado>();
    if (estado.perfilCalibrado) {
      _cambiarPestana(1);
    } else {
      context.push('/calibracion');
    }
  }

  Widget _construirVista() {
    switch (_indiceSeleccionado) {
      case 1:
        return const PantallaCuestionario();
      case 2:
        return const PantallaHistorial();
      case 3:
        return PantallaPerfil(key: _clavePerfil);
      case 4:
        return PantallaAjustes(alCambiarTab: _cambiarPestana);
      default:
        return VistaPanelPrincipal(alIniciarDiagnostico: _iniciarDiagnostico);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esInicio = _indiceSeleccionado == 0;
    return PopScope(
      canPop: esInicio,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _volver();
      },
      child: Scaffold(
        backgroundColor: TemaApp.blancoFondo,
        appBar: AppBar(
          title: Text(
            _titulos[_indiceSeleccionado],
            style: const TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold),
          ),
          backgroundColor: TemaApp.blancoFondo,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: esInicio
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: TemaApp.rojoPrimario),
                  tooltip: 'Volver',
                  onPressed: _volver,
                ),
        ),
        body: _construirVista(),
        bottomNavigationBar: BarraNavegacion(
          indiceSeleccionado: _indiceSeleccionado,
          alCambiarFila: _cambiarPestana,
        ),
      ),
    );
  }
}
