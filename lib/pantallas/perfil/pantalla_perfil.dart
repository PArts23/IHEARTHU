import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/nucleo/validadores.dart';
import 'package:iheart/datos/repositorio_perfil.dart';
import 'package:iheart/pantallas/inicio/vista_panel_principal.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => EstadoPantallaPerfil();
}

class EstadoPantallaPerfil extends State<PantallaPerfil> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorEdad = TextEditingController();
  final _controladorPeso = TextEditingController();
  final _controladorAltura = TextEditingController();
  final List<TextInputFormatter> _formatoDecimal = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
    LengthLimitingTextInputFormatter(6),
  ];

  String? _sexoSeleccionado;
  double? _imcCalculado;
  Map<String, String?> _valoresOriginales = {};

  @override
  void initState() {
    super.initState();
    _cargarDesdePerfil(context.read<ProveedorEstado>().perfil);
    _controladorPeso.addListener(_recalcularImc);
    _controladorAltura.addListener(_recalcularImc);
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorEdad.dispose();
    _controladorPeso.dispose();
    _controladorAltura.dispose();
    super.dispose();
  }

  String _formatearDecimal(double? valor) {
    if (valor == null) return '';
    return valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : valor.toString();
  }

  void _cargarDesdePerfil(PerfilPaciente? perfil) {
    _controladorNombre.text = perfil?.nombreCompleto ?? '';
    _controladorEdad.text = perfil?.edad?.toString() ?? '';
    _controladorPeso.text = _formatearDecimal(perfil?.pesoKg);
    _controladorAltura.text = _formatearDecimal(perfil?.alturaM);
    _sexoSeleccionado = perfil?.sexo;
    _valoresOriginales = _valoresActuales();
    _imcCalculado = Validadores.calcularImc(
      Validadores.convertirDecimal(_controladorPeso.text),
      Validadores.convertirDecimal(_controladorAltura.text),
    );
  }

  Map<String, String?> _valoresActuales() {
    return {
      'nombre': _controladorNombre.text.trim(),
      'edad': _controladorEdad.text.trim(),
      'sexo': _sexoSeleccionado,
      'peso': _controladorPeso.text.trim(),
      'altura': _controladorAltura.text.trim(),
    };
  }

  bool get tieneCambiosSinGuardar {
    final actuales = _valoresActuales();
    return actuales.entries.any((entrada) => _valoresOriginales[entrada.key] != entrada.value);
  }

  void descartarCambios() {
    if (!mounted) return;
    setState(() => _cargarDesdePerfil(context.read<ProveedorEstado>().perfil));
  }

  void _recalcularImc() {
    final imc = Validadores.calcularImc(
      Validadores.convertirDecimal(_controladorPeso.text),
      Validadores.convertirDecimal(_controladorAltura.text),
    );
    if (imc != _imcCalculado) setState(() => _imcCalculado = imc);
  }

  bool _hayCamposVacios() {
    return _controladorNombre.text.trim().isEmpty ||
        _controladorEdad.text.trim().isEmpty ||
        _controladorPeso.text.trim().isEmpty ||
        _controladorAltura.text.trim().isEmpty ||
        _sexoSeleccionado == null;
  }

  Future<void> _guardar() async {
    final valido = _formularioClave.currentState!.validate();
    if (!valido) {
      context.mostrarMensajeError(
        _hayCamposVacios()
            ? 'Complete los datos biométricos requeridos para actualizar su perfil.'
            : 'Datos no válidos. Revise los campos resaltados.',
      );
      return;
    }
    final estado = context.read<ProveedorEstado>();
    final perfilActual = estado.perfil;
    if (perfilActual == null) return;

    final perfilActualizado = PerfilPaciente(
      id: perfilActual.id,
      nombreCompleto: _controladorNombre.text.trim(),
      numeroDni: perfilActual.numeroDni,
      correo: perfilActual.correo,
      edad: int.tryParse(_controladorEdad.text.trim()),
      sexo: _sexoSeleccionado,
      pesoKg: Validadores.convertirDecimal(_controladorPeso.text),
      alturaM: Validadores.convertirDecimal(_controladorAltura.text),
      imc: _imcCalculado,
      ciudad: perfilActual.ciudad,
      pais: perfilActual.pais,
      tokenJwt: perfilActual.tokenJwt,
      tokenExpiraEn: perfilActual.tokenExpiraEn,
      versionModeloLocal: perfilActual.versionModeloLocal,
    );

    try {
      await estado.actualizarPerfil(perfilActualizado);
      if (!mounted) return;
      setState(() => _valoresOriginales = _valoresActuales());
      context.mostrarMensajeExito('Perfil actualizado con éxito');
    } catch (e) {
      if (mounted) context.mostrarMensajeError('Error al guardar: ${e.toString()}');
    }
  }

  Widget _construirCabecera(PerfilPaciente? perfil) {
    final nombre = perfil?.nombreCompleto ?? 'Paciente';
    final edad = perfil?.edad;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: TemaApp.rojoPrimario,
            child: Text(
              VistaPanelPrincipal.obtenerIniciales(nombre),
              style: const TextStyle(fontSize: 32, color: TemaApp.blancoFondo, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro)),
          const SizedBox(height: 4),
          Text(
            '${edad != null ? '$edad años · ' : ''}${perfil?.ciudad ?? 'Lima'}, ${perfil?.pais ?? 'Perú'}',
            style: const TextStyle(fontSize: 14, color: TemaApp.textoSecundario),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorSexo() {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('sexo-${_sexoSeleccionado ?? ''}'),
      initialValue: _sexoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Sexo',
        prefixIcon: const Icon(Icons.wc, color: TemaApp.textoSecundario),
        filled: true,
        fillColor: TemaApp.grisSuperficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.grisBorde),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
        DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
      ],
      onChanged: (valor) => setState(() => _sexoSeleccionado = valor),
      validator: (valor) => valor == null ? 'Seleccione su sexo' : null,
    );
  }

  Widget _construirMedidas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoTexto(
            controlador: _controladorPeso,
            etiqueta: 'Peso (kg)',
            iconoPrefijo: Icons.scale_outlined,
            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
            formateadores: _formatoDecimal,
            modoValidacion: AutovalidateMode.onUserInteraction,
            validador: Validadores.peso,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CampoTexto(
            controlador: _controladorAltura,
            etiqueta: 'Altura (m)',
            pista: 'Ej. 1.75',
            iconoPrefijo: Icons.height_outlined,
            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
            formateadores: _formatoDecimal,
            modoValidacion: AutovalidateMode.onUserInteraction,
            validador: Validadores.altura,
          ),
        ),
      ],
    );
  }

  Widget _construirImc() {
    final imc = _imcCalculado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: TemaApp.grisSuperficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: TemaApp.textoSecundario),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Índice de masa corporal (IMC)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
          ),
          Text(
            imc != null ? imc.toStringAsFixed(1) : '--',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorEstado>().perfil;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formularioClave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _construirCabecera(perfil),
            const SizedBox(height: 32),
            CampoTexto(
              controlador: _controladorNombre,
              etiqueta: 'Nombre completo',
              iconoPrefijo: Icons.person_outline,
              modoValidacion: AutovalidateMode.onUserInteraction,
              validador: Validadores.nombreCompleto,
            ),
            const SizedBox(height: 24),
            CampoTexto(
              controlador: _controladorEdad,
              etiqueta: 'Edad (años)',
              iconoPrefijo: Icons.calendar_today_outlined,
              tipoTeclado: TextInputType.number,
              formateadores: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              validador: Validadores.edad,
            ),
            const SizedBox(height: 24),
            _construirSelectorSexo(),
            const SizedBox(height: 24),
            _construirMedidas(),
            const SizedBox(height: 24),
            _construirImc(),
            const SizedBox(height: 32),
            BotonPrimario(texto: 'Actualizar mi perfil', alPresionar: _guardar),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
