import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iheart/datos/base_datos_local.dart';
import 'package:iheart/nucleo/constantes.dart';
import 'package:sqflite/sqflite.dart';

class PerfilPaciente {
  final int id;
  final String nombreCompleto;
  final String numeroDni;
  final String correo;
  final int? edad;
  final String? sexo;
  final double? pesoKg;
  final double? alturaM;
  final double? imc;
  final String ciudad;
  final String pais;
  final String? tokenJwt;
  final String? tokenExpiraEn;
  final int versionModeloLocal;

  const PerfilPaciente({
    required this.id,
    required this.nombreCompleto,
    required this.numeroDni,
    required this.correo,
    this.edad,
    this.sexo,
    this.pesoKg,
    this.alturaM,
    this.imc,
    required this.ciudad,
    required this.pais,
    this.tokenJwt,
    this.tokenExpiraEn,
    required this.versionModeloLocal,
  });

  factory PerfilPaciente.desdeMapa(Map<String, Object?> mapa) {
    return PerfilPaciente(
      id: mapa['id'] as int,
      nombreCompleto: mapa['nombre_completo'] as String,
      numeroDni: mapa['numero_dni'] as String,
      correo: mapa['correo'] as String,
      edad: mapa['edad'] as int?,
      sexo: mapa['sexo'] as String?,
      pesoKg: mapa['peso_kg'] as double?,
      alturaM: mapa['altura_m'] as double?,
      imc: mapa['imc'] as double?,
      ciudad: mapa['ciudad'] as String? ?? 'Lima',
      pais: mapa['pais'] as String? ?? 'Perú',
      tokenJwt: mapa['token_jwt'] as String?,
      tokenExpiraEn: mapa['token_expira_en'] as String?,
      versionModeloLocal: mapa['version_modelo_local'] as int? ?? 0,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'numero_dni': numeroDni,
      'correo': correo,
      'edad': edad,
      'sexo': sexo,
      'peso_kg': pesoKg,
      'altura_m': alturaM,
      'imc': imc,
      'ciudad': ciudad,
      'pais': pais,
      'token_jwt': tokenJwt,
      'token_expira_en': tokenExpiraEn,
      'version_modelo_local': versionModeloLocal,
    };
  }
}

class RepositorioPerfil {
  final BaseDatosLocal _baseDatos = BaseDatosLocal.instancia;
  final FlutterSecureStorage _almacenamientoSeguro = const FlutterSecureStorage();

  Future<PerfilPaciente?> obtenerPerfil() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query('perfil_paciente', limit: 1);
    if (listado.isEmpty) {
      return null;
    }
    return PerfilPaciente.desdeMapa(listado.first);
  }

  Future<void> guardarPerfil(PerfilPaciente perfil) async {
    final db = await _baseDatos.baseDatos;
    
    double? imcCalculado;
    if (perfil.pesoKg != null && perfil.alturaM != null && perfil.alturaM! > 0) {
      imcCalculado = perfil.pesoKg! / (perfil.alturaM! * perfil.alturaM!);
      imcCalculado = double.parse(imcCalculado.toStringAsFixed(1));
    }

    final perfilActualizado = PerfilPaciente(
      id: perfil.id,
      nombreCompleto: perfil.nombreCompleto,
      numeroDni: perfil.numeroDni,
      correo: perfil.correo,
      edad: perfil.edad,
      sexo: perfil.sexo,
      pesoKg: perfil.pesoKg,
      alturaM: perfil.alturaM,
      imc: imcCalculado,
      ciudad: perfil.ciudad,
      pais: perfil.pais,
      tokenJwt: perfil.tokenJwt,
      tokenExpiraEn: perfil.tokenExpiraEn,
      versionModeloLocal: perfil.versionModeloLocal,
    );

    await db.insert(
      'perfil_paciente',
      perfilActualizado.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (perfil.tokenJwt != null) {
      await _almacenamientoSeguro.write(key: Constantes.claveTokenJwt, value: perfil.tokenJwt);
    }
  }

  Future<void> actualizarToken(String token, String expira) async {
    final db = await _baseDatos.baseDatos;
    await db.update(
      'perfil_paciente',
      {'token_jwt': token, 'token_expira_en': expira},
    );
    await _almacenamientoSeguro.write(key: Constantes.claveTokenJwt, value: token);
  }

  Future<String?> obtenerTokenSeguro() async {
    return await _almacenamientoSeguro.read(key: Constantes.claveTokenJwt);
  }

  Future<void> eliminarPerfiles() async {
    final db = await _baseDatos.baseDatos;
    await db.delete('perfil_paciente');
  }

  Future<void> cerrarSesion() async {
    final db = await _baseDatos.baseDatos;
    await db.update('perfil_paciente', {'token_jwt': null, 'token_expira_en': null});
    await _almacenamientoSeguro.delete(key: Constantes.claveTokenJwt);
  }
}
