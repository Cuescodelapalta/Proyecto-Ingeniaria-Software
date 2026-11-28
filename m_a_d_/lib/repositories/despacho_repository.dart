import 'dart:convert';
import 'dart:io';

import 'package:m_a_d_/orden_despacho.dart';

/// Guarda y consulta órdenes de despacho en `ordenes_despacho.json`.
class DespachoRepository {
  static const String _filePath = 'ordenes_despacho.json';
  static const String _unidadesPath = 'unidades.json';

  /// Tiempo que una orden puede estar "Pendiente" antes de pasar a "En ruta"
  static const Duration ventanaPreparacion = Duration(minutes: 15);

  /// Agrega una orden al archivo; el ID debe ser único.
  static Future<void> guardarOrden(OrdenDespacho orden) async {
    if (orden.sedeOrigen.trim().isEmpty ||
        orden.centroMedicoDestino.trim().isEmpty ||
        orden.unidadesIds.isEmpty) {
      throw ArgumentError(
        'La orden de despacho está incompleta: debe incluir sede de origen, '
        'destino y al menos una unidad.',
      );
    }

    final ordenes = await _leerOrdenes();
    if (ordenes.any((actual) => actual.id == orden.id)) {
      throw StateError('Ya existe una orden de despacho con ID ${orden.id}.');
    }

    ordenes.add(orden);
    final contenido = const JsonEncoder.withIndent('  ')
        .convert(ordenes.map((actual) => actual.toJson()).toList());
    await File(_filePath).writeAsString(contenido);
  }

  /// Devuelve todas las órdenes guardadas, o una lista vacía si no hay archivo.
  static Future<List<OrdenDespacho>> obtenerOrdenes() => _leerOrdenes();

  /// Busca una orden por ID; devuelve null si no existe.
  static Future<OrdenDespacho?> obtenerOrdenPorId(int id) async {
    final ordenes = await _leerOrdenes();
    for (final orden in ordenes) {
      if (orden.id == id) return orden;
    }
    return null;
  }

  static Future<List<OrdenDespacho>> _leerOrdenes() async {
    final file = File(_filePath);
    if (!await file.exists()) return [];

    final contenido = await file.readAsString();
    if (contenido.trim().isEmpty) return [];

    final dynamic datos = jsonDecode(contenido);
    if (datos is! List) {
      throw const FormatException(
        'ordenes_despacho.json debe contener una lista válida.',
      );
    }

    return datos.map((dynamic dato) {
      if (dato is! Map) {
        throw const FormatException(
          'Cada orden de despacho debe ser un objeto JSON válido.',
        );
      }
      return OrdenDespacho.fromJson(Map<String, dynamic>.from(dato));
    }).toList();
  }

  static Future<void> _escribirOrdenes(List<OrdenDespacho> ordenes) async {
    final contenido = const JsonEncoder.withIndent('  ')
        .convert(ordenes.map((actual) => actual.toJson()).toList());
    await File(_filePath).writeAsString(contenido);
  }

  /// Copia de la orden con los campos indicados cambiados.
  static OrdenDespacho _copiar(
    OrdenDespacho orden, {
    String? centroMedicoDestino,
    String? estado,
  }) {
    return OrdenDespacho(
      id: orden.id,
      fechaSolicitud: orden.fechaSolicitud,
      sedeOrigen: orden.sedeOrigen,
      centroMedicoDestino: centroMedicoDestino ?? orden.centroMedicoDestino,
      estado: estado ?? orden.estado,
      unidadesIds: orden.unidadesIds,
    );
  }

  /// Pasa a "En ruta" a las ordenes "Pendiente" cuya ventana de preparacion ya expiro, ademas, devuelve cuantas ordenes cambio.
  static Future<int> transicionarOrdenesVencidas({DateTime? ahora}) async {
    final referencia = ahora ?? DateTime.now();
    final ordenes = await _leerOrdenes();

    var cambios = 0;
    for (var i = 0; i < ordenes.length; i++) {
      final orden = ordenes[i];
      final vencida = !referencia.isBefore(
        orden.fechaSolicitud.add(ventanaPreparacion),
      );

      if (orden.estado == 'Pendiente' && vencida) {
        ordenes[i] = _copiar(orden, estado: 'En ruta');
        cambios++;
      }
    }

    if (cambios > 0) await _escribirOrdenes(ordenes);
    return cambios;
  }

  /// Marca como "Disponible" las unidades de `unidades.json` con esos IDs.
  static Future<void> _liberarUnidades(List<int> ids) async {
    final file = File(_unidadesPath);
    if (!await file.exists()) return;

    final contenido = await file.readAsString();
    if (contenido.trim().isEmpty) return;

    final dynamic datos = jsonDecode(contenido);
    if (datos is! List) {
      throw const FormatException(
        'unidades.json debe contener una lista valida.',
      );
    }

    for (final unidad in datos) {
      if (unidad is Map && ids.contains(unidad['id'])) {
        unidad['estado'] = 'Disponible';
      }
    }

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(datos));
  }

  /// Indice de la orden si existe y sigue "Pendiente" si no, lanza error.
  static int _indiceModificable(List<OrdenDespacho> ordenes, int idOrden) {
    final i = ordenes.indexWhere((orden) => orden.id == idOrden);
    if (i == -1) {
      throw StateError('No existe una orden de despacho con ID $idOrden.');
    }
    if (ordenes[i].estado != 'Pendiente') {
      throw DespachoNoModificableException(ordenes[i].estado);
    }
    return i;
  }

  /// Cancela una orden "Pendiente" y devuelve sus unidades a "Disponible" y
  /// lanza DespachoNoModificableException si la orden está "En ruta" o "Cancelada".
  static Future<void> cancelarOrden(int idOrden) async {
    await transicionarOrdenesVencidas();
    final ordenes = await _leerOrdenes();
    final i = _indiceModificable(ordenes, idOrden);

    await _liberarUnidades(ordenes[i].unidadesIds);
    ordenes[i] = _copiar(ordenes[i], estado: 'Cancelada');
    await _escribirOrdenes(ordenes);
  }

  /// Confirmacion manual de la salida fisica: "Pendiente" -> "En ruta", ademas,
  /// lanza DespachoNoModificableException si la orden ya no está "Pendiente".
  static Future<void> confirmarSalida(int idOrden) async {
    await transicionarOrdenesVencidas();
    final ordenes = await _leerOrdenes();
    final i = _indiceModificable(ordenes, idOrden);

    ordenes[i] = _copiar(ordenes[i], estado: 'En ruta');
    await _escribirOrdenes(ordenes);
  }

  /// Cambia el centro medico de destino de una orden "Pendiente" y
  /// lanza DespachoNoModificableException si la orden está "En ruta" o "Cancelada".
  static Future<void> actualizarDestino(
    int idOrden,
    String nuevoDestino,
  ) async {
    if (nuevoDestino.trim().isEmpty) {
      throw ArgumentError('El centro medico de destino no puede estar vacio.');
    }

    await transicionarOrdenesVencidas();
    final ordenes = await _leerOrdenes();
    final i = _indiceModificable(ordenes, idOrden);

    ordenes[i] = _copiar(ordenes[i], centroMedicoDestino: nuevoDestino.trim());
    await _escribirOrdenes(ordenes);
  }
}

/// Se lanza al intentar editar, cancelar o confirmar una orden que ya no esta en estado "Pendiente"
class DespachoNoModificableException implements Exception {
  DespachoNoModificableException(this.estado);
  final String estado;

  String get mensaje => switch (estado) {
    'En ruta' => 'No se puede modificar un despacho en ruta.',
    'Cancelada' => 'No se puede modificar un despacho cancelado.',
    _ => 'No se puede modificar un despacho en estado $estado.',
  };

  @override
  String toString() => 'DespachoNoModificableException: $mensaje';
}
