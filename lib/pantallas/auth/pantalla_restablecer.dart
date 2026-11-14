import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/validadores.dart';
import 'package:iheart/red/servicio_auth.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaRestablecer extends StatefulWidget {
  final String correoInicial;
  final String codigoInicial;

  const PantallaRestablecer({
    super.key,
    this.correoInicial = '',
    this.codigoInicial = '',
  });

  @override
  State<PantallaRestablecer> createState() => _PantallaRestablecerState();
}

class _PantallaRestablecerState extends State<PantallaRestablecer> {
  final _formularioClave = GlobalKey<FormState>();
  final ServicioAuth _servicioAuth = ServicioAuth();
  late final TextEditingController _controladorCorreo;
  late final TextEditingController _controladorCodigo;
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmar = TextEditingController();

  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;
  bool _guardando = false;
  bool _reenviando = false;

  @override
  void initState() {
    super.initState();
    _controladorCorreo = TextEditingController(text: widget.correoInicial);
    _controladorCodigo = TextEditingController(text: widget.codigoInicial);
  }

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorCodigo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formularioClave.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _servicioAuth.restablecerContrasena(
        correo: _controladorCorreo.text,
        codigo: _controladorCodigo.text,
        nuevaContrasena: _controladorContrasena.text,
        confirmarContrasena: _controladorConfirmar.text,
      );
      if (mounted) {
        context.mostrarMensajeExito('Contraseña actualizada. Inicie sesión con su nueva contraseña.');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _reenviarCodigo() async {
    final mensajeCorreo = _validarCorreo(_controladorCorreo.text);
    if (mensajeCorreo != null) {
      context.mostrarMensajeError(mensajeCorreo);
      return;
    }

    setState(() {
      _reenviando = true;
    });

    try {
      await _servicioAuth.solicitarRecuperacion(_controladorCorreo.text);
      if (mounted) {
        context.mostrarMensajeExito('Le enviamos un nuevo código de verificación.');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _reenviando = false;
        });
      }
    }
  }

  String? _validarCorreo(String? valor) => Validadores.correo(valor);

  String? _validarCodigo(String? valor) {
    final codigo = valor?.trim() ?? '';
    if (codigo.isEmpty) {
      return 'El código de verificación es obligatorio';
    }
    final esNumerico = RegExp(r'^\d+$').hasMatch(codigo);
    if (!esNumerico || codigo.length != Constantes.longitudCodigoVerificacion) {
      return 'El código debe tener ${Constantes.longitudCodigoVerificacion} dígitos';
    }
    return null;
  }

  String? _validarContrasena(String? valor) => Validadores.contrasenaSegura(valor);

  String? _validarConfirmacion(String? valor) =>
      Validadores.confirmacion(valor, _controladorContrasena.text);

  Widget _construirIconoVisibilidad(bool oculto, VoidCallback alPresionar) {
    return IconButton(
      icon: Icon(
        oculto ? Icons.visibility_off : Icons.visibility,
        color: TemaApp.textoSecundario,
      ),
      onPressed: alPresionar,
    );
  }

  List<Widget> _construirCampos() {
    return [
      CampoTexto(
        controlador: _controladorCorreo,
        etiqueta: 'Correo electrónico',
        pista: 'ejemplo@correo.com',
        iconoPrefijo: Icons.email_outlined,
        tipoTeclado: TextInputType.emailAddress,
        validador: _validarCorreo,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorCodigo,
        etiqueta: 'Código de verificación',
        pista: '${Constantes.longitudCodigoVerificacion} dígitos',
        iconoPrefijo: Icons.verified_user_outlined,
        tipoTeclado: TextInputType.number,
        validador: _validarCodigo,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorContrasena,
        etiqueta: 'Nueva contraseña',
        pista: 'Mín. 8 caracteres, número, mayúscula y símbolo',
        iconoPrefijo: Icons.lock_outlined,
        ocultarTexto: _ocultarContrasena,
        iconoSufijo: _construirIconoVisibilidad(
          _ocultarContrasena,
          () => setState(() => _ocultarContrasena = !_ocultarContrasena),
        ),
        validador: _validarContrasena,
      ),
      const SizedBox(height: 24),
      CampoTexto(
        controlador: _controladorConfirmar,
        etiqueta: 'Confirmar nueva contraseña',
        pista: 'Repita la contraseña',
        iconoPrefijo: Icons.lock_outlined,
        ocultarTexto: _ocultarConfirmar,
        iconoSufijo: _construirIconoVisibilidad(
          _ocultarConfirmar,
          () => setState(() => _ocultarConfirmar = !_ocultarConfirmar),
        ),
        validador: _validarConfirmacion,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a recuperar contraseña',
          onPressed: () => context.go('/recuperar'),
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
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: TemaApp.rojoPrimario,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Revise su bandeja de entrada. Ingrese el código de verificación que le enviamos o abra el enlace del correo desde este dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: TemaApp.textoSecundario,
                  ),
                ),
                const SizedBox(height: 32),
                ..._construirCampos(),
                const SizedBox(height: 32),
                BotonPrimario(
                  texto: 'Cambiar contraseña',
                  cargando: _guardando,
                  alPresionar: _cambiarContrasena,
                ),
                const SizedBox(height: 16),
                BotonSecundario(
                  texto: 'Reenviar código',
                  cargando: _reenviando,
                  alPresionar: _reenviarCodigo,
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
