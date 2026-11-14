import 'package:flutter_test/flutter_test.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:iheart/nucleo/validadores.dart';

void main() {
  group('Correo (CP004, CP005, CP018, CP019)', () {
    test('obligatorio', () => expect(Validadores.correo(''), Constantes.mensajeCorreoObligatorio));
    test('formato inválido', () => expect(Validadores.correo('usuarioemail.com'), Constantes.mensajeCorreoInvalido));
    test('formato válido', () => expect(Validadores.correo('usuario_prueba1.ihu@gmail.com'), isNull));
  });

  group('Contraseña (CP015)', () {
    test('rechaza contraseña corta', () => expect(Validadores.contrasenaSegura('123'), Constantes.mensajeContrasenaInsegura));
    test('rechaza sin carácter especial', () => expect(Validadores.contrasenaSegura('ClaveErronea2026'), Constantes.mensajeContrasenaInsegura));
    test('acepta ClaveSegura2026*', () => expect(Validadores.contrasenaSegura('ClaveSegura2026*'), isNull));
    test('confirmación distinta (CP014)', () {
      expect(Validadores.confirmacion('ClaveSegura2025*', 'ClaveSegura2026*'), Constantes.mensajeContrasenasNoCoinciden);
    });
  });

  group('DNI (CP011)', () {
    test('menos de 8 dígitos', () => expect(Validadores.dni('12345'), Constantes.mensajeDniInvalido));
    test('con letras', () => expect(Validadores.dni('ABC12345'), Constantes.mensajeDniInvalido));
    test('válido', () => expect(Validadores.dni('12345678'), isNull));
  });

  group('Perfil (CP039 a CP045)', () {
    test('IMC 75 kg / 1.75 m', () => expect(Validadores.calcularImc(75, 1.75), 24.5));
    test('peso atípico', () => expect(Validadores.peso('350'), Constantes.mensajePesoInvalido));
    test('altura atípica', () => expect(Validadores.altura('0.4'), Constantes.mensajeAlturaInvalida));
    test('IMC vacío con datos inválidos', () => expect(Validadores.calcularImc(null, 1.75), isNull));
    test('nombre obligatorio', () => expect(Validadores.nombreCompleto(''), Constantes.mensajeNombreObligatorio));
  });
}
