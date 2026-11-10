import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/validadores.dart';
import 'package:iheart/red/servicio_auth.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaRecuperar extends StatefulWidget {
  const PantallaRecuperar({super.key});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final ServicioAuth _servicioAuth = ServicioAuth();
  bool _enviando = false;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!_formularioClave.currentState!.validate()) return;

    setState(() {
      _enviando = true;
    });

    final correo = _controladorCorreo.text.trim().toLowerCase();
    try {
      await _servicioAuth.solicitarRecuperacion(correo);
      if (mounted) {
        context.mostrarMensajeExito('Le enviamos un código de verificación a $correo.');
        final ruta = Uri(path: '/restablecer', queryParameters: {'correo': correo});
        context.pushReplacement(ruta.toString());
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Recuperación de contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al inicio de sesión',
          onPressed: () => context.go('/login'),
        ),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formularioClave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingrese su correo electrónico y le enviaremos un código de verificación y un enlace para restablecer su contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: TemaApp.textoSecundario,
                  ),
                ),
                const SizedBox(height: 36),
                CampoTexto(
                  controlador: _controladorCorreo,
                  etiqueta: 'Correo electrónico',
                  pista: 'ejemplo@correo.com',
                  iconoPrefijo: Icons.email_outlined,
                  tipoTeclado: TextInputType.emailAddress,
                  validador: Validadores.correo,
                ),
                const SizedBox(height: 36),
                BotonPrimario(
                  texto: 'Restablecer contraseña',
                  cargando: _enviando,
                  alPresionar: _restablecer,
                ),
                const SizedBox(height: 16),
                BotonSecundario(
                  texto: 'Cancelar',
                  alPresionar: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
