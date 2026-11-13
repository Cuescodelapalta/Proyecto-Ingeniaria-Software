import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/validador_donacion.dart';

void main() {
  const String testFileDonantes = 'donantes.json';
  const String testFileUnidades = 'unidades.json';

  setUp(() async {
    // Limpiar archivos de prueba antes de cada test
    for (var path in [testFileDonantes, testFileUnidades]) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  });

  tearDown(() async {
    // Limpiar archivos de prueba despues de cada test
    for (var path in [testFileDonantes, testFileUnidades]) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  });

  group('ValidadorDonacion - Task 05 (Elegibilidad, Herencia y Sede)', () {
    test('Falla si no existe el archivo donantes.json', () async {
      final resultado = await ValidadorDonacion.procesarYGuardarUnidad(
        rutDonante: '1-9',
        fechaExtraccion: DateTime(2026, 11, 12),
        volumen: 450,
        sede: 'Sede Central',
      );

      expect(resultado['exito'], isFalse);
      expect(
        resultado['mensaje'],
        contains('No se encontró el archivo de donantes'),
      );
    });

    test('Falla si el RUT ingresado no está registrado', () async {
      await File(testFileDonantes).writeAsString(
        jsonEncode([
          {'rut': '9-9', 'elegibilidad': 'Apto', 'tipoSangre': 'A+'},
        ]),
      );

      final resultado = await ValidadorDonacion.procesarYGuardarUnidad(
        rutDonante: '1-9', // RUT que no existe
        fechaExtraccion: DateTime(2026, 11, 12),
        volumen: 450,
        sede: 'Sede Central',
      );

      expect(resultado['exito'], isFalse);
      expect(resultado['mensaje'], contains('no está registrado'));
    });

    test(
      'Falla si el donante no cumple con la elegibilidad (no es Apto)',
      () async {
        await File(testFileDonantes).writeAsString(
          jsonEncode([
            {'rut': '1-9', 'elegibilidad': 'Rechazado', 'tipoSangre': 'O-'},
          ]),
        );

        final resultado = await ValidadorDonacion.procesarYGuardarUnidad(
          rutDonante: '1-9',
          fechaExtraccion: DateTime(2026, 11, 12),
          volumen: 450,
          sede: 'Sede Central',
        );

        expect(resultado['exito'], isFalse);
        expect(resultado['mensaje'], contains('no cumple con la elegibilidad'));
      },
    );

    test('Éxito: Valida donante Apto, hereda tipo de sangre y guarda la unidad con sede', () async {
      await File(testFileDonantes).writeAsString(
        jsonEncode([
          {'rut': '12.345.678-5', 'elegibilidad': 'Apto', 'tipoSangre': 'B+'},
        ]),
      );

      final resultado = await ValidadorDonacion.procesarYGuardarUnidad(
        rutDonante: '123456785',
        fechaExtraccion: DateTime(2026, 11, 12),
        volumen: 450,
        sede: 'Sede Concepción Centro',
      );

      expect(resultado['exito'], isTrue);
      expect(resultado['mensaje'], contains('Tipo de sangre heredado: B+'));

      // Verificar que se creó el archivo de unidades y guardó todos los datos correctos
      final fileUnidades = File(testFileUnidades);
      expect(await fileUnidades.exists(), isTrue);

      final List<dynamic> unidades = jsonDecode(
        await fileUnidades.readAsString(),
      );
      expect(unidades.length, 1);
      expect(unidades.first['rut_donante'], '123456785');
      expect(unidades.first['tipo_sangre'], 'B+');
      expect(unidades.first['sede'], 'Sede Concepción Centro');
      expect(unidades.first['estado'], 'Disponible');
      expect(unidades.first['volumen'], 450);
    });
  });
}
