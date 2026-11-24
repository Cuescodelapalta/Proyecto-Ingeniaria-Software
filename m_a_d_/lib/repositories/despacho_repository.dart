import 'dart:convert';
import 'dart:io';

import 'package:m_a_d_/orden_despacho.dart';

/// Guarda y consulta órdenes de despacho en `ordenes_despacho.json`.
class DespachoRepository {
  static const String _filePath = 'ordenes_despacho.json';

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
}
