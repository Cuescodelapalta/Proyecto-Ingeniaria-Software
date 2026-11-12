import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';

void main() {
  const String testFilePath = 'unidades.json';

  setUp(() async {
    final file = File(testFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  tearDown(() async {
    final file = File(testFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  group('UnidadRepository - Task08 (Alineado al Esquema Conceptual)', () {
    test('Calcula fecha_caducidad (+42 días) e inyecta estado Disponible', () async {
      final fechaExtraccion = DateTime(2026, 11, 1);

      final guardadoExitoso = await UnidadRepository.guardarUnidad(
        tipoSangre: 'O-',
        fechaExtraccion: fechaExtraccion,
        volumen: 450,
        sede: 'Sede Concepción Central',
      );

      expect(guardadoExitoso, isTrue);

      final List<dynamic> unidades = jsonDecode(await File(testFilePath).readAsString());
      expect(unidades.length, 1);

      final unidad = unidades.first as Map<String, dynamic>;
      expect(unidad['id'], 1);
      expect(unidad['tipo_sangre'], 'O-');
      expect(unidad['estado'], 'Disponible');
      expect(unidad['fecha_extraccion'], '2026-11-01');
      expect(unidad['fecha_caducidad'], '2026-12-13');
      expect(unidad['volumen'], 450);
      expect(unidad['sede'], 'Sede Concepción Central'); // verificación de sede
    });

    test('Incrementa el id entero, mantiene unidades previas y registra sedes', () async {
      await UnidadRepository.guardarUnidad(
        tipoSangre: 'A+',
        fechaExtraccion: DateTime(2026, 10, 10),
        volumen: 450,
        sede: 'Sede Talcahuano',
      );

      await UnidadRepository.guardarUnidad(
        tipoSangre: 'B+',
        fechaExtraccion: DateTime(2026, 10, 15),
        volumen: 400,
        sede: 'Sede Chillán',
      );

      final List<dynamic> unidades = jsonDecode(await File(testFilePath).readAsString());
      expect(unidades.length, 2);
      expect(unidades[0]['id'], 1);
      expect(unidades[0]['sede'], 'Sede Talcahuano');
      expect(unidades[1]['id'], 2);
      expect(unidades[1]['fecha_caducidad'], '2026-11-26');
      expect(unidades[1]['estado'], 'Disponible');
      expect(unidades[1]['sede'], 'Sede Chillán');
    });
  });
}