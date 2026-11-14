import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/red/servicio_wearable.dart';
import 'package:iheart/datos/repositorio_dispositivos.dart';

class PantallaAjustes extends StatefulWidget {
  final ValueChanged<int>? alCambiarTab;

  const PantallaAjustes({super.key, this.alCambiarTab});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  Future<void> _confirmarCierreSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Confirmar', style: TextStyle(color: TemaApp.rojoError, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await context.read<ProveedorEstado>().cerrarSesion();
      if (!mounted) return;
      context.mostrarMensajeExito('Sesión cerrada correctamente');
      context.go('/login');
    } catch (e) {
      if (mounted) context.mostrarMensajeError('No se pudo cerrar sesión: ${e.toString()}');
    }
  }

  Future<void> _cambiarNotificaciones(bool activar) async {
    final estado = context.read<ProveedorEstado>();
    if (activar) {
      final permiso = await Permission.notification.request();
      if (!permiso.isGranted) {
        if (mounted) {
          context.mostrarMensajeError('Active el permiso de notificaciones en los ajustes del sistema para recibir alertas.');
        }
        await openAppSettings();
        return;
      }
    }
    await estado.cambiarNotificaciones(activar);
    if (!mounted) return;
    context.mostrarMensajeExito(activar ? 'Alertas cardíacas activadas' : 'Alertas cardíacas desactivadas');
  }

  BoxDecoration _decoracion() {
    return BoxDecoration(
      color: TemaApp.blancoFondo,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TemaApp.grisBorde),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
    );
  }

  Widget _icono(IconData icono, {Color color = TemaApp.rojoPrimario}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Icon(icono, color: color),
    );
  }

  Widget _tarjeta({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    VoidCallback? alPresionar,
    Widget? accion,
    Color colorSubtitulo = TemaApp.textoSecundario,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _decoracion(),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: _icono(icono),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitulo, style: TextStyle(color: colorSubtitulo)),
          trailing: accion ?? const Icon(Icons.arrow_forward_ios, size: 16, color: TemaApp.textoSecundario),
          onTap: alPresionar,
        ),
      ),
    );
  }

  String _resumenPerfil(ProveedorEstado estado) {
    final perfil = estado.perfil;
    if (perfil == null) return 'Información de perfil';
    final edad = perfil.edad;
    final imc = perfil.imc;
    final detalles = [
      if (edad != null) '$edad años',
      if (perfil.sexo != null) perfil.sexo,
      if (imc != null) 'IMC ${imc.toStringAsFixed(1)}',
    ].whereType<String>().join(' · ');
    return [
      perfil.nombreCompleto,
      perfil.correo,
      detalles.isEmpty ? 'Perfil médico incompleto' : detalles,
    ].join('\n');
  }

  (String, Color) _estadoDispositivo(EstadoWearable estado) {
    switch (estado) {
      case EstadoWearable.conectado:
        return ('Sincronización completa', TemaApp.verdeExito);
      case EstadoWearable.reconectando:
        return ('Reconectando...', TemaApp.amarilloAlerta);
      case EstadoWearable.desconectado:
        return ('Desconectado', TemaApp.rojoError);
      case EstadoWearable.bluetoothApagado:
        return ('Desconectado / Bluetooth apagado', TemaApp.rojoError);
      case EstadoWearable.sinVincular:
        return ('Toque para vincular un wearable', TemaApp.textoSecundario);
    }
  }

  Widget _tarjetaDispositivos() {
    final wearable = ServicioWearable.instancia;
    return ValueListenableBuilder<DispositivoIot?>(
      valueListenable: wearable.dispositivo,
      builder: (contexto, dispositivo, _) => ValueListenableBuilder<EstadoWearable>(
        valueListenable: wearable.estado,
        builder: (contextoEstado, estado, _) {
          final (texto, color) = _estadoDispositivo(dispositivo == null ? EstadoWearable.sinVincular : estado);
          return _tarjeta(
            titulo: 'Dispositivos Vinculados',
            subtitulo: '${dispositivo?.nombre ?? 'Sin dispositivo vinculado'}\n$texto',
            colorSubtitulo: color,
            icono: Icons.watch,
            alPresionar: () => context.push('/iot'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      children: [
        _tarjeta(
          titulo: 'Revisar modelo federado',
          subtitulo: estado.descripcionEstadoModelo,
          icono: Icons.model_training_outlined,
          alPresionar: () => context.push('/modelo_fl'),
        ),
        const SizedBox(height: 16),
        _tarjeta(
          titulo: 'Mi perfil',
          subtitulo: _resumenPerfil(estado),
          icono: Icons.person_outline,
          accion: TextButton(
            onPressed: () => widget.alCambiarTab?.call(3),
            child: const Text('Editar', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        _tarjeta(
          titulo: 'Notificaciones',
          subtitulo: 'Alertas cardíacas y recordatorios',
          icono: Icons.notifications_outlined,
          accion: Switch(
            value: estado.notificacionesActivas,
            activeThumbColor: TemaApp.blancoFondo,
            activeTrackColor: TemaApp.rojoPrimario,
            onChanged: _cambiarNotificaciones,
          ),
        ),
        const SizedBox(height: 16),
        _tarjetaDispositivos(),
        const SizedBox(height: 16),
        _tarjeta(
          titulo: 'Google Health Connect',
          subtitulo: 'Permisos y lecturas de frecuencia cardíaca y SpO2',
          icono: Icons.health_and_safety_outlined,
          alPresionar: () => context.push('/health_connect'),
        ),
        const SizedBox(height: 32),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: TemaApp.rojoError.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaApp.rojoError, width: 1.2),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.logout, color: TemaApp.rojoError),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoError, fontSize: 16),
              ),
              onTap: _confirmarCierreSesion,
            ),
          ),
        ),
      ],
    );
  }
}
