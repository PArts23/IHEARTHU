import 'package:iheart/datos/base_datos_local.dart';
import 'package:sqflite/sqflite.dart';

class DispositivoIot {
  final int? id;
  final String nombre;
  final String? marca;
  final String? modelo;
  final String? direccionMac;
  final String? tipo;
  final String? firmware;
  final int? bateriaPorcentaje;
  final String? ultimaSincronizacion;
  final bool activo;

  const DispositivoIot({
    this.id,
    required this.nombre,
    this.marca,
    this.modelo,
    this.direccionMac,
    this.tipo,
    this.firmware,
    this.bateriaPorcentaje,
    this.ultimaSincronizacion,
    this.activo = true,
  });

  factory DispositivoIot.desdeMapa(Map<String, Object?> mapa) {
    final id = mapa['id'];
    final nombre = mapa['nombre'];
    final marca = mapa['marca'];
    final modelo = mapa['modelo'];
    final mac = mapa['mac_address'];
    final tipo = mapa['tipo'];
    final firmware = mapa['firmware'];
    final bateria = mapa['bateria_porcentaje'];
    final sincronizacion = mapa['ultima_sincronizacion'];
    final activo = mapa['activo'];
    return DispositivoIot(
      id: id is int ? id : null,
      nombre: nombre is String ? nombre : 'Wearable',
      marca: marca is String ? marca : null,
      modelo: modelo is String ? modelo : null,
      direccionMac: mac is String ? mac : null,
      tipo: tipo is String ? tipo : null,
      firmware: firmware is String ? firmware : null,
      bateriaPorcentaje: bateria is int ? bateria : null,
      ultimaSincronizacion: sincronizacion is String ? sincronizacion : null,
      activo: activo is int ? activo == 1 : true,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'nombre': nombre,
      'marca': marca,
      'modelo': modelo,
      'mac_address': direccionMac,
      'tipo': tipo,
      'firmware': firmware,
      'bateria_porcentaje': bateriaPorcentaje,
      'ultima_sincronizacion': ultimaSincronizacion,
      'activo': activo ? 1 : 0,
    };
  }

  DispositivoIot copiarCon({String? firmware, int? bateriaPorcentaje, String? ultimaSincronizacion}) {
    return DispositivoIot(
      id: id,
      nombre: nombre,
      marca: marca,
      modelo: modelo,
      direccionMac: direccionMac,
      tipo: tipo,
      firmware: firmware ?? this.firmware,
      bateriaPorcentaje: bateriaPorcentaje ?? this.bateriaPorcentaje,
      ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
      activo: activo,
    );
  }
}

class RepositorioDispositivos {
  final BaseDatosLocal _baseDatos = BaseDatosLocal.instancia;

  Future<DispositivoIot?> obtenerDispositivoActivo() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'dispositivos_iot',
      where: 'activo = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (listado.isEmpty) return null;
    return DispositivoIot.desdeMapa(listado.first);
  }

  Future<void> guardarDispositivoActivo(DispositivoIot dispositivo) async {
    final db = await _baseDatos.baseDatos;
    await db.transaction((transaccion) async {
      await transaccion.update('dispositivos_iot', {'activo': 0});
      await transaccion.insert(
        'dispositivos_iot',
        dispositivo.aMapa(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> actualizarEstado(DispositivoIot dispositivo) async {
    final db = await _baseDatos.baseDatos;
    final mac = dispositivo.direccionMac;
    if (mac == null) return;
    await db.update(
      'dispositivos_iot',
      {
        'firmware': dispositivo.firmware,
        'bateria_porcentaje': dispositivo.bateriaPorcentaje,
        'ultima_sincronizacion': dispositivo.ultimaSincronizacion,
      },
      where: 'mac_address = ?',
      whereArgs: [mac],
    );
  }

  Future<void> desvincularTodos() async {
    final db = await _baseDatos.baseDatos;
    await db.update('dispositivos_iot', {'activo': 0});
  }
}
