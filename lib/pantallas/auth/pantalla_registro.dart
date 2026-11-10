import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/nucleo/validadores.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorDni = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmar = TextEditingController();

  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDni.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formularioClave.currentState!.validate()) {
      context.mostrarMensajeError('Complete correctamente todos los campos obligatorios.');
      return;
    }

    final estado = context.read<ProveedorEstado>();
    try {
      await estado.registrarUsuario(
        nombreCompleto: _controladorNombre.text,
        numeroDni: _controladorDni.text,
        correo: _controladorCorreo.text,
        contrasena: _controladorContrasena.text,
        confirmarContrasena: _controladorConfirmar.text,
      );
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(e.toString().replaceAll('Exception: ', ''));
      }
      return;
    }

    try {
      await estado.iniciarSesion(_controladorCorreo.text.trim(), _controladorContrasena.text);
      if (mounted) {
        context.mostrarMensajeExito('Cuenta creada con éxito. Complete su perfil médico.');
        context.irAPestana(3);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarMensajeExito('Cuenta creada con éxito. Inicie sesión.');
        context.go('/login');
      }
    }
  }

  Widget _construirIconoVisibilidad(bool oculto, VoidCallback alPresionar) {
    return IconButton(
      icon: Icon(
        oculto ? Icons.visibility_off : Icons.visibility,
        color: TemaApp.textoSecundario,
      ),
      onPressed: alPresionar,
    );
  }

  List<Widget> _construirCamposIdentidad() {
    return [
      CampoTexto(
        controlador: _controladorNombre,
        etiqueta: 'Nombre completo',
        pista: 'Ej. Juan Pérez',
        iconoPrefijo: Icons.person_outline,
        validador: Validadores.nombreCompleto,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorDni,
        etiqueta: 'Número de DNI',
        pista: '8 dígitos',
        iconoPrefijo: Icons.badge_outlined,
        tipoTeclado: TextInputType.number,
        formateadores: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(Constantes.longitudDni),
        ],
        validador: Validadores.dni,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorCorreo,
        etiqueta: 'Correo electrónico',
        pista: 'ejemplo@correo.com',
        iconoPrefijo: Icons.email_outlined,
        tipoTeclado: TextInputType.emailAddress,
        validador: Validadores.correo,
      ),
    ];
  }

  List<Widget> _construirCamposContrasena() {
    return [
      CampoTexto(
        controlador: _controladorContrasena,
        etiqueta: 'Contraseña',
        pista: 'Mín. 8 caracteres, número, mayúscula y símbolo',
        iconoPrefijo: Icons.lock_outlined,
        ocultarTexto: _ocultarContrasena,
        iconoSufijo: _construirIconoVisibilidad(
          _ocultarContrasena,
          () => setState(() => _ocultarContrasena = !_ocultarContrasena),
        ),
        validador: Validadores.contrasenaSegura,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorConfirmar,
        etiqueta: 'Confirmar contraseña',
        pista: 'Repita la contraseña',
        iconoPrefijo: Icons.lock_outlined,
        ocultarTexto: _ocultarConfirmar,
        iconoSufijo: _construirIconoVisibilidad(
          _ocultarConfirmar,
          () => setState(() => _ocultarConfirmar = !_ocultarConfirmar),
        ),
        validador: (valor) => Validadores.confirmacion(valor, _controladorContrasena.text),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Registro de paciente'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formularioClave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Cree su cuenta para llevar el control de su salud cardíaca',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: TemaApp.textoSecundario),
                ),
                const SizedBox(height: 32),
                ..._construirCamposIdentidad(),
                const SizedBox(height: 24),
                ..._construirCamposContrasena(),
                const SizedBox(height: 32),
                BotonPrimario(
                  texto: 'Crear nueva cuenta',
                  cargando: estado.cargando,
                  alPresionar: _registrar,
                ),
                const SizedBox(height: 16),
                BotonSecundario(
                  texto: 'Ya tengo una cuenta',
                  alPresionar: () => context.go('/login'),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Al registrarse, usted acepta que sus datos médicos e historial se procesen localmente en su dispositivo y nunca se compartan sin su autorización.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
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
