import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';

void main() {
  const String testFilePath = 'unidades.json';

  setUp(() async {
    final file = File(testFilePath);
    try {
      if (await file.exists()) {
        await file.writeAsString('[]');
      }
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

  group('Task09 - Filtrado y Ordenamiento de Unidades', () {
    test('Filtra por tipo de sangre y ordena por fecha más cercana a vencer', () async {
      // Unidad O- que vence más tarde
      await UnidadRepository.guardarUnidad(
        rutDonante: '123456742',
        tipoSangre: 'O-',
        fechaExtraccion: DateTime(2026, 11, 10),
        volumen: 450,
        sede: 'Sede A',
      );

      // Unidad A+ que debe ser ignorada por el filtro
      await UnidadRepository.guardarUnidad(
        rutDonante: '11111111K',
        tipoSangre: 'A+',
        fechaExtraccion: DateTime(2026, 11, 1),
        volumen: 450,
        sede: 'Sede B',
      );

      // Unidad O- que vence más pronto (debe quedar primera)
      await UnidadRepository.guardarUnidad(
        rutDonante: '87654321',
        tipoSangre: 'O-',
        fechaExtraccion: DateTime(2026, 11, 2),
        volumen: 450,
        sede: 'Sede C',
      );

      final resultado = await UnidadRepository.filtrarUnidades(tipoSangre: 'O-');

      expect(resultado.length, 2);
      expect(resultado[0]['tipo_sangre'], 'O-');
      expect(resultado[0]['sede'], 'Sede C'); // La que vence antes
      expect(resultado[1]['sede'], 'Sede A'); // La que vence despues
    });

    test('Omite las unidades que no están Disponibles', () async {
      final datosQuemados = [
        {
          'id': 1,
          'rut_donante': '123456742',
          'tipo_sangre': 'A+',
          'estado': 'Desechada',
          'fecha_caducidad': '2026-12-01',
          'fecha_extraccion': '2026-10-20',
          'volumen': 450,
          'sede': 'Sede A'
        },
        {
          'id': 2,
          'rut_donante': '11111111K',
          'tipo_sangre': 'A+',
          'estado': 'Disponible',
          'fecha_caducidad': '2026-12-10',
          'fecha_extraccion': '2026-10-29',
          'volumen': 450,
          'sede': 'Sede A'
        },
      ];
      await File(testFilePath).writeAsString(jsonEncode(datosQuemados));

      final disponibles = await UnidadRepository.filtrarUnidades(tipoSangre: 'A+');

      expect(disponibles.length, 1);
      expect(disponibles.first['id'], 2); // Solo trae la que esta Disponible
    });
  });
}