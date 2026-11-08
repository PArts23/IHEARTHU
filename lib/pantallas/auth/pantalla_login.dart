import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formularioClave.currentState!.validate()) return;

    final estado = context.read<ProveedorEstado>();
    try {
      await estado.iniciarSesion(_controladorCorreo.text, _controladorContrasena.text);
      if (mounted) {
        context.mostrarMensajeExito('Bienvenido a I HEART');
        context.go('/inicio');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formularioClave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.favorite,
                  color: TemaApp.rojoPrimario,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'I HEART',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.rojoPrimario,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Detección cardiovascular en tus manos',
                  style: TextStyle(
                    fontSize: 14,
                    color: TemaApp.textoSecundario,
                  ),
                ),
                const SizedBox(height: 48),
                CampoTexto(
                  controlador: _controladorCorreo,
                  etiqueta: 'Correo electrónico',
                  pista: 'ejemplo@correo.com',
                  iconoPrefijo: Icons.email_outlined,
                  tipoTeclado: TextInputType.emailAddress,
                  validador: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(valor)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CampoTexto(
                  controlador: _controladorContrasena,
                  etiqueta: 'Contraseña',
                  pista: '••••••••',
                  iconoPrefijo: Icons.lock_outlined,
                  ocultarTexto: _ocultarContrasena,
                  iconoSufijo: IconButton(
                    icon: Icon(
                      _ocultarContrasena ? Icons.visibility_off : Icons.visibility,
                      color: TemaApp.textoSecundario,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarContrasena = !_ocultarContrasena;
                      });
                    },
                  ),
                  validador: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (valor.length < Constantes.longitudMinimaContrasena) {
                      return 'La contraseña debe tener al menos ${Constantes.longitudMinimaContrasena} caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                BotonPrimario(
                  texto: 'Acceder',
                  cargando: estado.cargando,
                  alPresionar: _iniciarSesion,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.push('/recuperar'),
                  child: const Text(
                    'Olvidé mi contraseña',
                    style: TextStyle(
                      color: TemaApp.rojoPrimario,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(color: TemaApp.textoSecundario),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/registro'),
                      child: const Text(
                        'Registrar nueva cuenta',
                        style: TextStyle(
                          color: TemaApp.rojoPrimario,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  'Sus datos nunca salen de su dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: TemaApp.textoSecundario,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
