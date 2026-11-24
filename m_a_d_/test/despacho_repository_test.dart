import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/orden_despacho.dart';
import 'package:m_a_d_/repositories/despacho_repository.dart';

void main() {
  const testFilePath = 'ordenes_despacho.json';

  setUp(() async {
    final file = File(testFilePath);
    if (await file.exists()) await file.delete();
  });

  tearDown(() async {
    final file = File(testFilePath);
    if (await file.exists()) await file.delete();
  });

  OrdenDespacho crearOrden(int id) => OrdenDespacho(
    id: id,
    fechaSolicitud: DateTime(2026, 11, 24, 16, 30),
    sedeOrigen: 'Sede Central',
    centroMedicoDestino: 'Hospital Regional',
    unidadesIds: [12, 15],
  );

  group('DespachoRepository', () {
    test('guarda órdenes en JSON y permite consultarlas por ID', () async {
      final orden = crearOrden(1);
      await DespachoRepository.guardarOrden(orden);

      final List<dynamic> datos = jsonDecode(
        await File(testFilePath).readAsString(),
      );
      expect(datos, hasLength(1));
      expect(datos.single['estado'], 'Pendiente');
      expect(datos.single['unidades_ids'], [12, 15]);

      final ordenes = await DespachoRepository.obtenerOrdenes();
      expect(ordenes, hasLength(1));
      expect(ordenes.single.toJson(), orden.toJson());
      expect(
        (await DespachoRepository.obtenerOrdenPorId(1))?.toJson(),
        orden.toJson(),
      );
      expect(await DespachoRepository.obtenerOrdenPorId(99), isNull);
    });

    test('mantiene órdenes existentes y rechaza IDs duplicados', () async {
      await DespachoRepository.guardarOrden(crearOrden(1));
      await DespachoRepository.guardarOrden(crearOrden(2));

      expect(
        () => DespachoRepository.guardarOrden(crearOrden(1)),
        throwsStateError,
      );
      expect(
        (await DespachoRepository.obtenerOrdenes()).map((orden) => orden.id),
        [1, 2],
      );
    });

    test('devuelve una lista vacía si el archivo aún no existe', () async {
      expect(await DespachoRepository.obtenerOrdenes(), isEmpty);
    });
  });
}
