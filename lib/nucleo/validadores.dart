import 'package:iheart/nucleo/constantes.dart';

class Validadores {
  static final RegExp _patronCorreo = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final RegExp _patronMayuscula = RegExp(r'[A-ZÁÉÍÓÚÑ]');
  static final RegExp _patronNumero = RegExp(r'\d');
  static final RegExp _patronEspecial = RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑáéíóúñ\s]');
  static final RegExp _patronDni = RegExp(r'^\d{8}$');
  static final RegExp _patronDecimal = RegExp(r'^\d+([\.,]\d+)?$');

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return Constantes.mensajeCorreoObligatorio;
    if (!_patronCorreo.hasMatch(texto)) return Constantes.mensajeCorreoInvalido;
    return null;
  }

  static String? contrasenaObligatoria(String? valor) {
    if (valor == null || valor.isEmpty) return Constantes.mensajeContrasenaObligatoria;
    return null;
  }

  static bool esContrasenaSegura(String valor) {
    return valor.length >= Constantes.longitudMinimaContrasena &&
        _patronMayuscula.hasMatch(valor) &&
        _patronNumero.hasMatch(valor) &&
        _patronEspecial.hasMatch(valor);
  }

  static String? contrasenaSegura(String? valor) {
    if (valor == null || valor.isEmpty) return Constantes.mensajeContrasenaObligatoria;
    if (!esContrasenaSegura(valor)) return Constantes.mensajeContrasenaInsegura;
    return null;
  }

  static String? confirmacion(String? valor, String original) {
    if (valor == null || valor.isEmpty) return 'Confirme su contraseña';
    if (valor != original) return Constantes.mensajeContrasenasNoCoinciden;
    return null;
  }

  static String? nombreCompleto(String? valor) {
    if (valor == null || valor.trim().isEmpty) return Constantes.mensajeNombreObligatorio;
    return null;
  }

  static String? dni(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'El DNI es obligatorio';
    if (!_patronDni.hasMatch(texto)) return Constantes.mensajeDniInvalido;
    return null;
  }

  static double? convertirDecimal(String? valor) {
    final texto = valor?.trim() ?? '';
    if (!_patronDecimal.hasMatch(texto)) return null;
    return double.tryParse(texto.replaceAll(',', '.'));
  }

  static bool esPesoValido(double? peso) {
    return peso != null && peso >= Constantes.pesoMinimoKg && peso <= Constantes.pesoMaximoKg;
  }

  static bool esAlturaValida(double? altura) {
    return altura != null && altura >= Constantes.alturaMinimaM && altura <= Constantes.alturaMaximaM;
  }

  static bool esEdadValida(int? edad) {
    return edad != null && edad >= Constantes.edadMinima && edad <= Constantes.edadMaxima;
  }

  static String? peso(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'El peso es obligatorio';
    if (!esPesoValido(convertirDecimal(valor))) return Constantes.mensajePesoInvalido;
    return null;
  }

  static String? altura(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La altura es obligatoria';
    if (!esAlturaValida(convertirDecimal(valor))) return Constantes.mensajeAlturaInvalida;
    return null;
  }

  static String? edad(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La edad es obligatoria';
    if (!esEdadValida(int.tryParse(valor.trim()))) return Constantes.mensajeEdadInvalida;
    return null;
  }

  static double? calcularImc(double? peso, double? altura) {
    if (!esPesoValido(peso) || !esAlturaValida(altura) || peso == null || altura == null) {
      return null;
    }
    final imc = peso / (altura * altura);
    return double.parse(imc.toStringAsFixed(1));
  }
}
