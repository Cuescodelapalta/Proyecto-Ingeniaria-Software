import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';

void main() {
  const String testFilePath = 'unidades.json';
  setUp(() async {
    final file = File(testFilePath);
    try {
      if (await file.exists()) await file.writeAsString('[]');
    } catch (_) {}
  });

  tearDown(() async {
    final file = File(testFilePath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  });
  group('Sistema de actualización de estado de vencimiento', () {
    test('Test 1: Cambio automático a estado vencido', () async {
      final hoy = DateTime.now();
      final fechaAntigua = hoy.subtract(const Duration(days: 50));

      await UnidadRepository.guardarUnidad(
        rutDonante: '123456785',
        tipoSangre: 'O+',
        fechaExtraccion: fechaAntigua,
        volumen: 450,
        sede: 'Concepción',
      );
      await UnidadRepository.actualizarVencimientos();
      final unidades = await UnidadRepository.obtenerUnidades();
      expect(unidades.first['estado'], 'Vencida');
    });

    test('Test 2: Conservación de estado disponible', () async {
      final hoy = DateTime.now();
      await UnidadRepository.guardarUnidad(
        rutDonante: '987654321',
        tipoSangre: 'A-',
        fechaExtraccion: hoy,
        volumen: 450,
        sede: 'Talcahuano',
      );
      await UnidadRepository.actualizarVencimientos();

      final unidades = await UnidadRepository.obtenerUnidades();
      expect(unidades.first['estado'], 'Disponible');
    });

    test(
      'Test 3: Persistencia de los estados actualizados en el archivo ',
      () async {
        final hoy = DateTime.now();
        await UnidadRepository.guardarUnidad(
          rutDonante: '111111111',
          tipoSangre: 'B+',
          fechaExtraccion: hoy.subtract(const Duration(days: 60)),
          volumen: 450,
          sede: 'Chiguayante',
        );
        await UnidadRepository.actualizarVencimientos();
        final file = File(testFilePath);
        final String contenido = await file.readAsString();
        final List<dynamic> datos = jsonDecode(contenido);
        expect(datos.first['estado'], 'Vencida');
      },
    );
  });
}
