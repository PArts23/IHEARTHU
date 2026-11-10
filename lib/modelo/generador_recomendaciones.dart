import 'package:iheart/datos/repositorio_diagnosticos.dart';

class Recomendacion {
  final String texto;
  final String icono;
  final int prioridad;

  const Recomendacion({required this.texto, required this.icono, required this.prioridad});
}

class GeneradorRecomendaciones {
  static String clasificarNivel(double probabilidad) {
    if (probabilidad > 0.8) return 'crítico';
    if (probabilidad > 0.5) return 'alto';
    if (probabilidad > 0.25) return 'moderado';
    return 'bajo';
  }

  static List<Recomendacion> generar({
    required String nivelRiesgo,
    required CuestionarioClinico cuestionario,
  }) {
    final lista = <Recomendacion>[];
    final riesgoElevado = nivelRiesgo == 'alto' || nivelRiesgo == 'crítico';

    if (riesgoElevado) {
      lista.add(const Recomendacion(
        texto: 'Programe una cita con su cardiólogo a la brevedad para una evaluación presencial.',
        icono: 'doctor',
        prioridad: 3,
      ));
    }
    if (cuestionario.esFumadorActivo) {
      lista.add(const Recomendacion(
        texto: 'Dejar de fumar reduce significativamente su riesgo coronario. Solicite apoyo en su centro de salud.',
        icono: 'doctor',
        prioridad: 2,
      ));
    }
    if (cuestionario.tieneHipertension) {
      lista.add(const Recomendacion(
        texto: 'Controle su presión arterial regularmente y mantenga su tratamiento antihipertensivo indicado.',
        icono: 'doctor',
        prioridad: 2,
      ));
    }
    if (cuestionario.presentaDolorPecho) {
      lista.add(const Recomendacion(
        texto: 'Si el dolor en el pecho se intensifica, dura más de 15 minutos o se acompaña de falta de aire, acuda a emergencias.',
        icono: 'doctor',
        prioridad: 3,
      ));
    }
    lista.add(const Recomendacion(
      texto: 'Mantenga una dieta baja en sodio, azúcares y grasas saturadas, rica en frutas y verduras.',
      icono: 'diet',
      prioridad: 1,
    ));
    lista.add(const Recomendacion(
      texto: 'Realice actividad física moderada al menos 30 minutos al día, según tolerancia y consejo médico.',
      icono: 'exercise',
      prioridad: 1,
    ));

    lista.sort((a, b) => b.prioridad.compareTo(a.prioridad));
    return lista.take(4).toList();
  }
}
