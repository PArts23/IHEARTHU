import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_diagnosticos.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/modelo/feature_engineering.dart';
import 'package:iheart/modelo/generador_recomendaciones.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/pregunta_opciones.dart';
import 'package:iheart/red/servicio_biometrico.dart';

class PantallaCuestionario extends StatefulWidget {
  const PantallaCuestionario({super.key});

  @override
  State<PantallaCuestionario> createState() => _PantallaCuestionarioState();
}

class _PantallaCuestionarioState extends State<PantallaCuestionario> {
  static const List<OpcionPregunta<bool>> _opcionesSiNo = [
    OpcionPregunta(etiqueta: 'Sí', valor: true),
    OpcionPregunta(etiqueta: 'No', valor: false),
  ];

  static const Map<String, String> _enfermedades = {
    'diabetes': 'Diabetes Mellitus',
    'hipertension': 'Hipertensión Arterial',
    'cerebrovascular': 'Accidente Cerebrovascular',
    'renal': 'Insuficiencia Renal Crónica',
    'respiratoria': 'Enfermedad respiratoria crónica',
    'tiroidea': 'Enfermedad tiroidea',
    'cardiaca': 'Insuficiencia Cardíaca Congestiva',
    'dislipidemia': 'Dislipidemia',
  };

  double? _frecuenciaCardiaca;
  DateTime? _momentoLectura;
  String? _fuenteFrecuencia;
  bool _leyendoFrecuencia = false;
  bool _procesando = false;
  bool _mostrarPendientes = false;

  String? _estadoTabaco;
  bool? _antecedenteFamiliar;
  final Set<String> _enfermedadesSeleccionadas = {};
  bool _ningunaEnfermedad = false;
  bool? _edema;
  bool? _dolorPecho;
  int? _frecuenciaDolor;
  String? _tipoDolor;
  bool? _esfuerzoFisico;
  bool _disnea = false;

  bool get _enfermedadesRespondidas => _ningunaEnfermedad || _enfermedadesSeleccionadas.isNotEmpty;

  List<String> _preguntasPendientes() {
    final pendientes = <String>[];
    if (_frecuenciaCardiaca == null) pendientes.add('frecuencia');
    if (_estadoTabaco == null) pendientes.add('tabaco');
    if (_antecedenteFamiliar == null) pendientes.add('familiar');
    if (!_enfermedadesRespondidas) pendientes.add('enfermedades');
    if (_edema == null) pendientes.add('edema');
    if (_dolorPecho == null) pendientes.add('dolor');
    if (_dolorPecho == true && _frecuenciaDolor == null) pendientes.add('frecuencia_dolor');
    if (_dolorPecho == true && _tipoDolor == null) pendientes.add('tipo_dolor');
    if (_esfuerzoFisico == null) pendientes.add('esfuerzo');
    return pendientes;
  }

  bool? _obesidadSegunImc(ProveedorEstado estado) {
    final imc = estado.perfil?.imc;
    if (imc == null) return null;
    return imc >= Constantes.imcUmbralObesidad;
  }

  Future<void> _registrarFrecuencia() async {
    setState(() => _leyendoFrecuencia = true);
    try {
      final servicio = ServicioBiometrico.instancia;
      final permiso = await servicio.solicitarAutorizacion(const [
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      ]);
      if (!permiso) {
        if (mounted) context.mostrarMensajeError('Se requiere permiso de Health Connect para leer la frecuencia cardíaca.');
        return;
      }
      final ahora = DateTime.now();
      final datos = await servicio.obtenerDatosFrecuenciaCardiaca(ahora.subtract(const Duration(hours: 6)), ahora);
      final lectura = datos.isNotEmpty ? datos.last : null;
      final valor = lectura?.value;
      if (lectura == null || valor is! NumericHealthValue || valor.numericValue <= 0) {
        if (mounted) {
          context.mostrarMensajeError('No se encontró una lectura reciente. Mida su ritmo en el wearable o ingréselo manualmente.');
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _frecuenciaCardiaca = valor.numericValue.toDouble();
        _momentoLectura = DateTime.now();
        _fuenteFrecuencia = lectura.sourceName;
      });
    } catch (e) {
      if (mounted) context.mostrarMensajeError('Error al leer Health Connect: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _leyendoFrecuencia = false);
    }
  }

  Future<void> _ingresarFrecuenciaManual() async {
    final controlador = TextEditingController();
    final valor = await showDialog<double>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Ingresar frecuencia cardíaca'),
        content: TextField(
          controller: controlador,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          decoration: const InputDecoration(suffixText: 'bpm', hintText: 'Ej. 72'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextoDialogo).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final numero = double.tryParse(controlador.text);
              if (numero != null && numero >= 30 && numero <= 220) {
                Navigator.of(contextoDialogo).pop(numero);
              }
            },
            child: const Text('Registrar', style: TextStyle(color: TemaApp.rojoPrimario)),
          ),
        ],
      ),
    );
    controlador.dispose();
    if (valor == null || !mounted) return;
    setState(() {
      _frecuenciaCardiaca = valor;
      _momentoLectura = DateTime.now();
      _fuenteFrecuencia = null;
    });
  }

  CuestionarioClinico _construirCuestionario(bool obesidad) {
    final dolor = _dolorPecho == true;
    final tipo = dolor ? _tipoDolor : null;
    return CuestionarioClinico(
      tieneDiabetes: _enfermedadesSeleccionadas.contains('diabetes'),
      tieneHipertension: _enfermedadesSeleccionadas.contains('hipertension'),
      tieneAccidenteCerebrovascular: _enfermedadesSeleccionadas.contains('cerebrovascular'),
      tieneInsuficienciaRenal: _enfermedadesSeleccionadas.contains('renal'),
      tieneEnfermedadRespiratoria: _enfermedadesSeleccionadas.contains('respiratoria'),
      tieneEnfermedadTiroidea: _enfermedadesSeleccionadas.contains('tiroidea'),
      tieneInsuficienciaCardiaca: _enfermedadesSeleccionadas.contains('cardiaca'),
      tieneDislipidemia: _enfermedadesSeleccionadas.contains('dislipidemia'),
      tieneObesidad: obesidad,
      esFumadorActivo: _estadoTabaco == 'activo',
      esExFumador: _estadoTabaco == 'ex_fumador',
      antecedenteFamiliarCad: _antecedenteFamiliar == true,
      presentaEdema: _edema == true,
      presentaDolorPecho: dolor,
      frecuenciaDolorPecho: dolor ? (_frecuenciaDolor ?? 0) : 0,
      clasificacionDolor: tipo == 'tipico' ? 2 : (tipo == 'atipico' ? 1 : 0),
      tipoDolor: tipo,
      esfuerzoFisicoReciente: _esfuerzoFisico == true,
      disnea: _disnea,
      creadoEn: DateTime.now().toIso8601String(),
    );
  }

  Future<SesionMonitoreo> _construirSesion(double frecuencia) async {
    final servicio = ServicioBiometrico.instancia;
    final saturacion = await servicio.obtenerUltimoValor(HealthDataType.BLOOD_OXYGEN, const Duration(hours: 24));
    final variabilidad = await servicio.obtenerUltimoValor(
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      const Duration(hours: 24),
    );
    final saturacionPorcentaje = saturacion != null && saturacion <= 1 ? saturacion * 100 : saturacion;
    final fuente = _fuenteFrecuencia;
    return SesionMonitoreo(
      tipo: fuente != null ? 'reposo' : 'manual',
      bpmPromedio: frecuencia,
      spo2Promedio: saturacionPorcentaje,
      hrvMs: variabilidad,
      fuente: fuente != null ? 'smartwatch' : 'manual',
      dispositivoNombre: fuente ?? 'Ingreso manual del paciente',
      duracionSegundos: 0,
      iniciadoEn: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _ejecutarDiagnostico() async {
    final pendientes = _preguntasPendientes();
    if (pendientes.isNotEmpty) {
      setState(() => _mostrarPendientes = true);
      context.mostrarMensajeError(Constantes.mensajeCuestionarioIncompleto);
      return;
    }
    final estado = context.read<ProveedorEstado>();
    final perfil = estado.perfil;
    final frecuencia = _frecuenciaCardiaca;
    final obesidad = _obesidadSegunImc(estado);
    if (perfil == null || frecuencia == null || obesidad == null || !estado.perfilCompleto) {
      context.mostrarMensajeError('${Constantes.mensajePerfilIncompleto}. Complete su perfil para continuar.');
      return;
    }
    if (!estado.perfilCalibrado) {
      context.push('/calibracion');
      return;
    }
    setState(() => _procesando = true);
    try {
      final cuestionario = _construirCuestionario(obesidad);
      final sesion = await _construirSesion(frecuencia);
      final promedio = await ServicioBiometrico.instancia.obtenerPromedio(
        HealthDataType.HEART_RATE,
        const Duration(hours: 6),
      );
      final features = FeatureEngineering.generarFeatures(
        perfil: perfil,
        cuestionario: cuestionario,
        ritmoCardiaco: frecuencia,
      );
      final probabilidad = await InferenciaLocal.instancia.ejecutarInferencia(features);
      final nivelRiesgo = GeneradorRecomendaciones.clasificarNivel(probabilidad);
      await estado.registrarDiagnosticoCompleto(
        sesion: sesion,
        cuestionario: cuestionario,
        probabilidad: probabilidad,
        riesgo: nivelRiesgo,
        etiqueta: probabilidad >= 0.5 ? 'CAD' : 'Normal',
        featuresJson: features.toString(),
      );
      if (!mounted) return;
      context.go('/resultado', extra: <String, Object?>{
        'probabilidad': probabilidad,
        'riesgo': nivelRiesgo,
        'nombre': perfil.nombreCompleto,
        'frecuencia_promedio': promedio ?? frecuencia,
        'hrv': sesion.hrvMs,
        'recomendaciones': GeneradorRecomendaciones.generar(nivelRiesgo: nivelRiesgo, cuestionario: cuestionario),
      });
    } catch (e) {
      if (mounted) context.mostrarMensajeError('Error al ejecutar diagnóstico: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  BoxDecoration _decoracionTarjeta({bool resaltar = false}) {
    return BoxDecoration(
      color: TemaApp.blancoFondo,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: resaltar ? TemaApp.rojoError : TemaApp.grisBorde),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }

  String _textoMomento() {
    final momento = _momentoLectura;
    if (momento == null) return 'Sin lectura registrada';
    final minutos = DateTime.now().difference(momento).inMinutes;
    if (minutos < 1) return 'ahora';
    return 'hace $minutos min';
  }

  Widget _construirTarjetaFrecuencia() {
    final frecuencia = _frecuenciaCardiaca;
    final pendiente = _mostrarPendientes && frecuencia == null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoracionTarjeta(resaltar: pendiente),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: TemaApp.rojoPrimario, size: 24),
              SizedBox(width: 12),
              Text('Frecuencia cardíaca', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${frecuencia?.toStringAsFixed(0) ?? '0'} bpm',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_textoMomento(), style: const TextStyle(color: TemaApp.textoSecundario)),
              ),
            ],
          ),
          if (_fuenteFrecuencia != null)
            Text('Sincronizado vía: $_fuenteFrecuencia', style: const TextStyle(fontSize: 12, color: TemaApp.verdeExito)),
          if (pendiente)
            const Text('Registre su frecuencia cardíaca', style: TextStyle(fontSize: 12, color: TemaApp.rojoError)),
          const SizedBox(height: 16),
          _construirBotonesFrecuencia(),
        ],
      ),
    );
  }

  Widget _construirBotonesFrecuencia() {
    final estilo = OutlinedButton.styleFrom(
      foregroundColor: TemaApp.rojoPrimario,
      side: const BorderSide(color: TemaApp.rojoPrimario),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _leyendoFrecuencia ? null : _registrarFrecuencia,
            icon: _leyendoFrecuencia
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.rojoPrimario),
                  )
                : const Icon(Icons.watch_outlined, size: 18),
            label: Text(_leyendoFrecuencia ? 'Leyendo...' : 'Registrar frecuencia'),
            style: estilo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _ingresarFrecuenciaManual,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ingresar manual'),
            style: estilo,
          ),
        ),
      ],
    );
  }

  Widget _construirObesidad(ProveedorEstado estado) {
    final obesidad = _obesidadSegunImc(estado);
    final imc = estado.perfil?.imc;
    return PreguntaOpciones<bool>(
      pregunta: '¿Padece de obesidad?',
      ayuda: imc != null
          ? 'Calculado automáticamente según su IMC (${imc.toStringAsFixed(1)}).'
          : 'Complete su peso y altura en "Mi perfil" para calcularlo.',
      opciones: _opcionesSiNo,
      seleccion: obesidad,
      alSeleccionar: null,
    );
  }

  Widget _construirEnfermedades() {
    final pendiente = _mostrarPendientes && !_enfermedadesRespondidas;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pendiente ? TemaApp.rojoError : Colors.transparent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Padece o ha padecido alguna de las siguientes enfermedades?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._enfermedades.entries.map((entrada) => _construirChipEnfermedad(entrada.key, entrada.value)),
              FilterChip(
                label: const Text('Ninguna'),
                selected: _ningunaEnfermedad,
                selectedColor: TemaApp.rojoPrimario.withValues(alpha: 0.15),
                onSelected: (valor) => setState(() {
                  _ningunaEnfermedad = valor;
                  if (valor) _enfermedadesSeleccionadas.clear();
                }),
              ),
            ],
          ),
          if (pendiente)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Respuesta requerida', style: TextStyle(fontSize: 12, color: TemaApp.rojoError)),
            ),
        ],
      ),
    );
  }

  Widget _construirChipEnfermedad(String clave, String etiqueta) {
    return FilterChip(
      label: Text(etiqueta),
      selected: _enfermedadesSeleccionadas.contains(clave),
      selectedColor: TemaApp.rojoPrimario.withValues(alpha: 0.15),
      checkmarkColor: TemaApp.rojoPrimario,
      onSelected: (valor) => setState(() {
        if (valor) {
          _enfermedadesSeleccionadas.add(clave);
          _ningunaEnfermedad = false;
        } else {
          _enfermedadesSeleccionadas.remove(clave);
        }
      }),
    );
  }

  List<Widget> _construirPreguntasHabitos() {
    return [
      PreguntaOpciones<String>(
        pregunta: '¿Es fumador o ha dejado de fumar?',
        opciones: const [
          OpcionPregunta(etiqueta: 'No fumo', valor: 'no_fumador'),
          OpcionPregunta(etiqueta: 'Soy fumador activo', valor: 'activo'),
          OpcionPregunta(etiqueta: 'He dejado de fumar', valor: 'ex_fumador'),
        ],
        seleccion: _estadoTabaco,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _estadoTabaco = valor),
      ),
      PreguntaOpciones<bool>(
        pregunta: '¿Algún familiar suyo ha presentado enfermedad coronaria prematura?',
        opciones: _opcionesSiNo,
        seleccion: _antecedenteFamiliar,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _antecedenteFamiliar = valor),
      ),
      _construirEnfermedades(),
      PreguntaOpciones<bool>(
        pregunta: '¿Presenta edemas (hinchazón por acumulación de líquido en los tejidos)?',
        opciones: _opcionesSiNo,
        seleccion: _edema,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _edema = valor),
      ),
    ];
  }

  List<Widget> _construirPreguntasDolor() {
    final dolorActivo = _dolorPecho == true;
    return [
      PreguntaOpciones<bool>(
        pregunta: '¿Presenta dolores en el pecho?',
        opciones: _opcionesSiNo,
        seleccion: _dolorPecho,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() {
          _dolorPecho = valor;
          if (!valor) {
            _frecuenciaDolor = null;
            _tipoDolor = null;
          }
        }),
      ),
      PreguntaOpciones<int>(
        pregunta: '¿Con qué frecuencia?',
        ayuda: '1 = muy rara vez · 5 = muy frecuente',
        opciones: List.generate(5, (indice) => OpcionPregunta(etiqueta: '${indice + 1}', valor: indice + 1)),
        seleccion: _frecuenciaDolor,
        habilitada: dolorActivo,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _frecuenciaDolor = valor),
      ),
      PreguntaOpciones<String>(
        pregunta: '¿Cómo clasificaría el dolor?',
        opciones: const [
          OpcionPregunta(etiqueta: 'Dolor típico (anginoso)', valor: 'tipico'),
          OpcionPregunta(etiqueta: 'Dolor atípico', valor: 'atipico'),
          OpcionPregunta(etiqueta: 'Dolor no anginoso', valor: 'no_anginoso'),
        ],
        seleccion: _tipoDolor,
        habilitada: dolorActivo,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _tipoDolor = valor),
      ),
      PreguntaOpciones<bool>(
        pregunta: '¿Ha hecho algún esfuerzo físico reciente?',
        opciones: _opcionesSiNo,
        seleccion: _esfuerzoFisico,
        mostrarPendiente: _mostrarPendientes,
        alSeleccionar: (valor) => setState(() => _esfuerzoFisico = valor),
      ),
      SwitchListTile(
        title: const Text('¿Presenta dificultad respiratoria (disnea)? (opcional)', style: TextStyle(fontSize: 14)),
        value: _disnea,
        activeThumbColor: TemaApp.rojoPrimario,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onChanged: (valor) => setState(() => _disnea = valor),
      ),
    ];
  }

  Widget _construirTarjetaPreguntas(String titulo, IconData icono, List<Widget> preguntas) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icono, color: TemaApp.rojoPrimario, size: 24),
                const SizedBox(width: 12),
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...preguntas,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Complete los datos clínicos a continuación para procesar la estimación de riesgo.',
            style: TextStyle(fontSize: 14, color: TemaApp.textoSecundario),
          ),
          const SizedBox(height: 24),
          _construirTarjetaFrecuencia(),
          const SizedBox(height: 24),
          _construirTarjetaPreguntas('Antecedentes de salud', Icons.assignment_outlined, [
            _construirObesidad(estado),
            ..._construirPreguntasHabitos(),
          ]),
          const SizedBox(height: 24),
          _construirTarjetaPreguntas('Síntomas recientes', Icons.warning_amber_rounded, _construirPreguntasDolor()),
          const SizedBox(height: 32),
          BotonPrimario(
            texto: 'COMENZAR DIAGNÓSTICO',
            cargando: _procesando,
            alPresionar: _ejecutarDiagnostico,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
