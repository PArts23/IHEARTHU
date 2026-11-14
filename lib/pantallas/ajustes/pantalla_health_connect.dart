import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';
import 'package:iheart/red/servicio_biometrico.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/widgets/barra_navegacion.dart';

class ResultadoTipoSalud {
  final HealthDataType tipo;
  final String nombre;
  final IconData icono;
  final bool tienePermiso;
  final List<HealthDataPoint> puntos;
  final String? error;

  const ResultadoTipoSalud({
    required this.tipo,
    required this.nombre,
    required this.icono,
    required this.tienePermiso,
    required this.puntos,
    this.error,
  });
}

class PantallaHealthConnect extends StatefulWidget {
  const PantallaHealthConnect({super.key});

  @override
  State<PantallaHealthConnect> createState() => _PantallaHealthConnectState();
}

class _PantallaHealthConnectState extends State<PantallaHealthConnect> with WidgetsBindingObserver {
  final List<HealthDataType> _tiposPrincipales = const [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  ];

  bool _disponible = false;
  bool _autorizado = false;
  bool _cargando = true;
  bool _cargandoAccion = false;
  bool _escaneandoCrudo = false;
  int _horasRango = 24;
  List<HealthDataPoint> _ultimasLecturas = [];
  List<ResultadoTipoSalud> _resultadosCrudos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarEstado();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed &&
        !_cargando &&
        !_cargandoAccion &&
        !_escaneandoCrudo) {
      _verificarEstado();
    }
  }

  Future<void> _verificarEstado() async {
    setState(() {
      _cargando = true;
    });

    try {
      final bool disponible = await ServicioBiometrico.instancia
          .esHealthConnectDisponible();
      if (!mounted) return;
      setState(() {
        _disponible = disponible;
      });

      if (disponible) {
        final bool tienePermisos = await ServicioBiometrico.instancia
            .verificarPermisos(const [HealthDataType.HEART_RATE]);
        if (!mounted) return;
        setState(() {
          _autorizado = tienePermisos;
        });

        if (_autorizado) {
          await _cargarLecturasRecientes();
        }
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(
          'Error al verificar Health Connect: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _solicitarAutorizacionCompleta() async {
    setState(() {
      _cargandoAccion = true;
    });

    try {
      final bool permisoConcedido = await ServicioBiometrico.instancia
          .solicitarAutorizacion(_tiposPrincipales);
      final bool accesoCardiaco = await ServicioBiometrico.instancia
          .verificarPermisos(const [HealthDataType.HEART_RATE]);
      if (!mounted) return;
      setState(() {
        _autorizado = accesoCardiaco;
      });

      if (permisoConcedido) {
        if (mounted) {
          context.mostrarMensajeExito(
            'Permisos de Health Connect concedidos exitosamente.',
          );
        }
      } else {
        if (mounted) {
          context.mostrarMensajeError(
            'No se concedieron todos los permisos. El escaneo mostrará el acceso de cada tipo.',
          );
        }
      }
      if (accesoCardiaco) await _cargarLecturasRecientes();
      if (mounted) await _ejecutarEscaneoCrudo();
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(
          'Error al solicitar autorización: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoAccion = false;
        });
      }
    }
  }

  Future<void> _revocarAutorizacion() async {
    setState(() {
      _cargandoAccion = true;
    });

    try {
      await ServicioBiometrico.instancia.revocarPermisos();
      if (!mounted) return;
      setState(() {
        _autorizado = false;
        _ultimasLecturas.clear();
        _resultadosCrudos.clear();
      });
      if (mounted) {
        context.mostrarMensajeExito('Conexión revocada con éxito.');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(
          'Error al revocar permisos: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoAccion = false;
        });
      }
    }
  }

  Future<void> _cargarLecturasRecientes() async {
    try {
      final ahora = DateTime.now();
      final haceHoras = ahora.subtract(Duration(hours: _horasRango));
      final datos = await ServicioBiometrico.instancia
          .obtenerDatosFrecuenciaCardiaca(haceHoras, ahora);
      if (!mounted) return;
      setState(() {
        _ultimasLecturas = datos.reversed.toList();
      });
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(
          'Error al cargar lecturas: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _escribirLecturaPrueba() async {
    setState(() {
      _cargandoAccion = true;
    });

    try {
      final ahora = DateTime.now();
      final exito = await ServicioBiometrico.instancia
          .escribirFrecuenciaCardiacaPrueba(76.0, ahora);
      if (!mounted) return;
      if (exito) {
        if (mounted) {
          context.mostrarMensajeExito(
            'Lectura de prueba (76 bpm) escrita en Health Connect.',
          );
        }
        await _cargarLecturasRecientes();
        await _ejecutarEscaneoCrudo();
      } else {
        if (mounted) {
          context.mostrarMensajeError(
            'No se pudo escribir en Health Connect. Verifique permisos de escritura.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al escribir: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoAccion = false;
        });
      }
    }
  }

  Future<void> _ejecutarEscaneoCrudo() async {
    if (!mounted || _escaneandoCrudo) return;
    setState(() {
      _escaneandoCrudo = true;
    });

    final List<ResultadoTipoSalud> lista = [];
    final ahora = DateTime.now();
    final inicio = ahora.subtract(Duration(hours: _horasRango));

    final mapaTipos = <HealthDataType, Map<String, Object>>{
      HealthDataType.HEART_RATE: {
        'nombre': 'Frecuencia Cardíaca (HR)',
        'icono': Icons.favorite,
      },
      HealthDataType.RESTING_HEART_RATE: {
        'nombre': 'Frecuencia Cardíaca en Reposo',
        'icono': Icons.favorite_border,
      },
      HealthDataType.BLOOD_OXYGEN: {
        'nombre': 'Saturación de Oxígeno (SpO2)',
        'icono': Icons.opacity,
      },
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC: {
        'nombre': 'Presión Arterial Sistólica',
        'icono': Icons.speed,
      },
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC: {
        'nombre': 'Presión Arterial Diastólica',
        'icono': Icons.speed_outlined,
      },
      HealthDataType.STEPS: {
        'nombre': 'Conteo de Pasos',
        'icono': Icons.directions_walk,
      },
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD: {
        'nombre': 'Variabilidad Cardíaca (HRV RMSSD)',
        'icono': Icons.timeline,
      },
    };

    for (final entrada in mapaTipos.entries) {
      final tipo = entrada.key;
      final info = entrada.value;
      final nombre = switch (info['nombre']) {
        String valor => valor,
        _ => tipo.name,
      };
      final icono = switch (info['icono']) {
        IconData valor => valor,
        _ => Icons.health_and_safety,
      };

      bool tienePermiso = false;
      List<HealthDataPoint> puntos = [];
      String? errorMensaje;

      try {
        tienePermiso = await ServicioBiometrico.instancia.verificarPermisos([
          tipo,
        ]);
        if (tienePermiso) {
          puntos = await ServicioBiometrico.instancia.obtenerDatosPorTipo(
            tipo,
            inicio,
            ahora,
          );
        }
      } catch (err) {
        errorMensaje = err.toString();
      }

      lista.add(
        ResultadoTipoSalud(
          tipo: tipo,
          nombre: nombre,
          icono: icono,
          tienePermiso: tienePermiso,
          puntos: puntos,
          error: errorMensaje,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _resultadosCrudos = lista;
        _escaneandoCrudo = false;
      });
      context.mostrarMensajeExito('Escaneo de Health Connect finalizado.');
    }
  }

  String _formatearFecha(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    return '$dia/$mes/$anio $hora:$minuto:$segundo';
  }

  Widget _construirCabeceraEstado() {
    final String estadoTexto = _disponible
        ? (_autorizado ? 'CONECTADO' : 'NO VINCULADO')
        : 'NO DISPONIBLE';
    final Color estadoColor = _disponible
        ? (_autorizado ? TemaApp.verdeExito : TemaApp.amarilloAlerta)
        : TemaApp.rojoError;

    return Material(
      color: Colors.transparent,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TemaApp.blancoFondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TemaApp.grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: TemaApp.rojoPrimario,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Google Health Connect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TemaApp.textoOscuro,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoTexto,
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sincronización directa y lectura de datos biométricos de salud desde el repositorio oficial de Android.',
              style: TextStyle(fontSize: 13, color: TemaApp.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAccionesConexion() {
    if (!_disponible) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TemaApp.grisSuperficie,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Health Connect no está instalado o no es compatible con este dispositivo.',
              style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BotonPrimario(
              texto: 'Verificar disponibilidad',
              alPresionar: _verificarEstado,
            ),
          ],
        ),
      );
    }

    if (!_autorizado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Para que la app pueda leer su frecuencia cardíaca y SpO2, debe otorgar permisos de acceso a Health Connect.',
            style: TextStyle(color: TemaApp.textoSecundario, fontSize: 14),
          ),
          const SizedBox(height: 24),
          BotonPrimario(
            texto: 'Conceder Permisos Health Connect',
            alPresionar: _solicitarAutorizacionCompleta,
            cargando: _cargandoAccion,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: BotonSecundario(
                texto: 'Revocar Permisos',
                alPresionar: _revocarAutorizacion,
                cargando: _cargandoAccion,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BotonPrimario(
                texto: 'Sincronizar',
                alPresionar: _cargarLecturasRecientes,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirSelectorRango() {
    return Row(
      children: [
        const Text(
          'Rango de tiempo:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: TemaApp.textoOscuro,
          ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: _horasRango,
          underline: const SizedBox.shrink(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: TemaApp.rojoPrimario,
            fontSize: 13,
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Última 1 hora')),
            DropdownMenuItem(value: 6, child: Text('Últimas 6 horas')),
            DropdownMenuItem(value: 24, child: Text('Últimas 24 horas')),
            DropdownMenuItem(value: 168, child: Text('Últimos 7 días')),
            DropdownMenuItem(value: 720, child: Text('Últimos 30 días')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _horasRango = val;
              });
              _cargarLecturasRecientes();
            }
          },
        ),
      ],
    );
  }

  Widget _construirSeccionDiagnosticoCrudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.troubleshoot, color: TemaApp.rojoPrimario, size: 20),
            SizedBox(width: 8),
            Text(
              'Inspector de Datos en Crudo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TemaApp.textoOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Escanee los tipos de datos compatibles para ver exactamente qué información tiene Health Connect registrada en su teléfono.',
          style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BotonPrimario(
                texto: _escaneandoCrudo
                    ? 'Escaneando...'
                    : 'Escanear Todo Health Connect',
                cargando: _escaneandoCrudo,
                alPresionar: _escaneandoCrudo ? () {} : _ejecutarEscaneoCrudo,
              ),
            ),
          ],
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BotonSecundario(
                  texto: 'Inyectar Lectura de Prueba (76 bpm)',
                  alPresionar: _cargandoAccion ? () {} : _escribirLecturaPrueba,
                  cargando: _cargandoAccion,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (_resultadosCrudos.isNotEmpty) ...[
          const Text(
            'Resultados del Escaneo:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: TemaApp.textoOscuro,
            ),
          ),
          const SizedBox(height: 12),
          ..._resultadosCrudos.map(
            (res) => _construirTarjetaResultadoCrudo(res),
          ),
        ],
      ],
    );
  }

  Widget _construirTarjetaResultadoCrudo(ResultadoTipoSalud res) {
    final bool tieneDatos = res.puntos.isNotEmpty;
    final Color colorEstado = !res.tienePermiso
        ? TemaApp.rojoError
        : (tieneDatos ? TemaApp.verdeExito : TemaApp.amarilloAlerta);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorEstado.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(res.icono, color: colorEstado, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  res.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.error != null
                      ? 'Error'
                      : !res.tienePermiso
                      ? 'Sin Permiso'
                      : (tieneDatos ? '${res.puntos.length} datos' : '0 datos'),
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (res.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: ${res.error}',
              style: const TextStyle(color: TemaApp.rojoError, fontSize: 11),
            ),
          ],
          if (res.tienePermiso && !tieneDatos) ...[
            const SizedBox(height: 8),
            const Text(
              'No hay registros en Health Connect para este rango. Verifique que su app de smartwatch (Mi Fitness, Zepp, etc.) tenga la sincronización con Health Connect activada.',
              style: TextStyle(fontSize: 11, color: TemaApp.textoSecundario),
            ),
          ],
          if (tieneDatos) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...res.puntos.take(3).map((punto) {
              String valorStr = '';
              final valor = punto.value;
              if (valor is NumericHealthValue) {
                valorStr = '${valor.numericValue} ${punto.unit.name}';
              } else {
                valorStr = valor.toString();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatearFecha(punto.dateFrom)} · ${punto.sourceName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: TemaApp.textoSecundario,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      valorStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (res.puntos.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${res.puntos.length - 3} lecturas adicionales...',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaApp.rojoPrimario,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _construirListaLecturas() {
    if (!_autorizado || !_disponible) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lecturas de Frecuencia Cardíaca',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TemaApp.textoOscuro,
              ),
            ),
            Text(
              '${_ultimasLecturas.length} encontradas',
              style: const TextStyle(
                fontSize: 12,
                color: TemaApp.textoSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_ultimasLecturas.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TemaApp.grisSuperficie,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: TemaApp.textoSecundario),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se encontraron lecturas en este rango de tiempo.',
                    style: TextStyle(
                      color: TemaApp.textoSecundario,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._ultimasLecturas.take(5).map((lectura) {
            final valor = lectura.value;
            double bpm = 0;
            if (valor is NumericHealthValue) {
              bpm = valor.numericValue.toDouble();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    color: TemaApp.blancoFondo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaApp.grisBorde),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(
                      Icons.favorite,
                      color: TemaApp.rojoClaro,
                    ),
                    title: Text(
                      '${bpm.toStringAsFixed(0)} bpm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                    subtitle: Text(
                      _formatearFecha(lectura.dateFrom),
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaApp.textoSecundario,
                      ),
                    ),
                    trailing: Text(
                      lectura.sourceName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TemaApp.rojoPrimario,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Google Health Connect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a Ajustes',
          onPressed: () => context.canPop() ? context.pop() : context.irAPestana(4),
        ),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      bottomNavigationBar: BarraNavegacion(
        indiceSeleccionado: 4,
        alCambiarFila: (indice) => context.irAPestana(indice),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: TemaApp.rojoPrimario),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                children: [
                  _construirCabeceraEstado(),
                  const SizedBox(height: 24),
                  _construirAccionesConexion(),
                  const SizedBox(height: 24),
                  _construirSelectorRango(),
                  const SizedBox(height: 16),
                  _construirListaLecturas(),
                  const SizedBox(height: 32),
                  _construirSeccionDiagnosticoCrudo(),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}
