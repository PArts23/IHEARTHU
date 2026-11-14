import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_modelo.dart';
import 'package:iheart/red/servicio_conectividad.dart';
import 'package:iheart/red/servicio_dispositivo_local.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/widgets/boton_primario.dart';

class PantallaModeloFL extends StatefulWidget {
  const PantallaModeloFL({super.key});

  @override
  State<PantallaModeloFL> createState() => _PantallaModeloFLState();
}

class _PantallaModeloFLState extends State<PantallaModeloFL> {
  final ServicioConectividad _conectividad = ServicioConectividad.instancia;
  Timer? _temporizadorBateria;
  String _modeloTelefono = 'Smartphone';
  int? _bateria;

  @override
  void initState() {
    super.initState();
    _conectividad.suscribir();
    _cargarDispositivo();
    _temporizadorBateria = Timer.periodic(const Duration(seconds: 30), (_) => _actualizarBateria());
  }

  @override
  void dispose() {
    _temporizadorBateria?.cancel();
    _conectividad.cancelarSuscripcion();
    super.dispose();
  }

  Future<void> _cargarDispositivo() async {
    final modelo = await ServicioDispositivoLocal.instancia.obtenerModelo();
    if (mounted) setState(() => _modeloTelefono = modelo);
    await _actualizarBateria();
  }

  Future<void> _actualizarBateria() async {
    final nivel = await ServicioDispositivoLocal.instancia.obtenerNivelBateria();
    if (mounted) setState(() => _bateria = nivel);
  }

  String _formatearSincronizacion(String? valor) {
    if (valor == null) return 'Nunca';
    final fecha = DateTime.tryParse(valor)?.toLocal();
    if (fecha == null) return valor;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  Future<void> _solicitarEntrenamiento() async {
    final estado = context.read<ProveedorEstado>();
    if (estado.historial.length < Constantes.cantidadMinimaSesionesEntrenamiento) {
      context.mostrarMensajeError(
        'Se requieren al menos ${Constantes.cantidadMinimaSesionesEntrenamiento} diagnósticos locales para entrenar (actual: ${estado.historial.length}).',
      );
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Consentimiento de datos'),
        content: const Text(
          '¿Desea iniciar el entrenamiento local y subir únicamente los pesos numéricos del modelo al servidor? Sus datos clínicos jamás saldrán de su dispositivo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Aceptar y subir', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await estado.entrenarYSubirPesosFL();
      if (mounted) context.mostrarMensajeExito('Entrenamiento completado y pesos subidos con éxito.');
    } catch (e) {
      if (mounted) context.mostrarMensajeError('Error en entrenamiento federado: ${e.toString()}');
    }
  }

  Widget _construirBanner(bool enLinea, EstadoModeloFl? modelo) {
    final color = enLinea ? TemaApp.verdeExito : TemaApp.textoSecundario;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(enLinea ? Icons.check_circle : Icons.cloud_off, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enLinea ? 'Federated Learning activo' : 'Fuera de línea',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  enLinea ? 'Nodo conectado al servidor de agregación' : 'Sincronización pausada',
                  style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                ),
                Text(
                  'Última sincronización: ${_formatearSincronizacion(modelo?.ultimaSincronizacion)}',
                  style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                ),
                Text(
                  'Ronda federada: ${modelo?.rondaActual ?? 0} · Versión del modelo: v${modelo?.versionLocal ?? 0}',
                  style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEstadoCalibracion(ProveedorEstado estado) {
    final calibrado = estado.perfilCalibrado;
    final color = calibrado ? TemaApp.verdeExito : TemaApp.amarilloAlerta;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(calibrado ? Icons.verified_outlined : Icons.tune, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(estado.descripcionEstadoModelo, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _construirPrivacidad() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TemaApp.grisSuperficie, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: TemaApp.rojoPrimario, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Privacidad: sus datos clínicos permanecen en su dispositivo. Solo se comparten los pesos numéricos del modelo.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMetrica(String nombre, String descripcion, double? valor, bool enLinea) {
    final colorIndicador = enLinea ? TemaApp.verdeExito : TemaApp.amarilloAlerta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: colorIndicador, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(descripcion, style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario)),
              ],
            ),
          ),
          Text(
            valor != null ? '${(valor * 100).toStringAsFixed(1)} %' : '--',
            style: const TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario),
          ),
        ],
      ),
    );
  }

  Widget _construirMetricas(bool enLinea, EstadoModeloFl? modelo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: Column(
        children: [
          _construirMetrica('Accuracy', 'Proporción de predicciones correctas.', Constantes.accuracyModeloGlobal, enLinea),
          _construirMetrica('Precision', 'Clasificaciones positivas correctas respecto al total de clasificaciones.',
              Constantes.precisionModeloGlobal, enLinea),
          _construirMetrica('Recall', 'Instancias relevantes de una clase positiva.', Constantes.recallModeloGlobal, enLinea),
          _construirMetrica('F1-Score', 'Precisión + Recall', Constantes.f1ModeloGlobal, enLinea),
        ],
      ),
    );
  }

  Widget _construirDispositivo(bool enLinea) {
    final bateria = _bateria;
    return ValueListenableBuilder<EstadoWearable>(
      valueListenable: ServicioWearable.instancia.estado,
      builder: (contexto, estadoWearable, _) {
        final ppgActivo = estadoWearable == EstadoWearable.conectado || estadoWearable == EstadoWearable.sinVincular;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaApp.blancoFondo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TemaApp.grisBorde),
          ),
          child: Row(
            children: [
              const Icon(Icons.smartphone, color: TemaApp.rojoPrimario, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_modeloTelefono, style: const TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${enLinea ? 'Conectado' : 'Desconectado'} · Batería: ${bateria != null ? '$bateria%' : '--'}',
                      style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (ppgActivo ? TemaApp.verdeExito : TemaApp.textoSecundario).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ppgActivo ? 'PPG activo' : 'PPG inactivo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ppgActivo ? TemaApp.verdeExito : TemaApp.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final modelo = estado.estadoModelo;
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Modelo predictivo FL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.irAPestana(4),
        ),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _conectividad.enLinea,
        builder: (contexto, enLinea, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            _construirBanner(enLinea, modelo),
            const SizedBox(height: 12),
            _construirEstadoCalibracion(estado),
            const SizedBox(height: 12),
            _construirPrivacidad(),
            const SizedBox(height: 24),
            const Text('Métricas de desempeño del modelo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _construirMetricas(enLinea, modelo),
            const SizedBox(height: 24),
            const Text('Dispositivo local', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _construirDispositivo(enLinea),
            const SizedBox(height: 32),
            BotonPrimario(
              texto: 'ENTRENAR Y SUBIR PESOS',
              cargando: estado.cargando,
              alPresionar: enLinea ? _solicitarEntrenamiento : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        indiceSeleccionado: 4,
        alCambiarFila: (indice) => context.irAPestana(indice),
      ),
    );
  }
}
