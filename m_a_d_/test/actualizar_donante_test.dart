import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

void main() {
  const String filePath = 'donantes.json';

  Map<String, dynamic> donanteBase(String rut) => {
    'rut': rut,
    'nombre': 'Donante Prueba',
    'fechaNacimiento': '1995-05-10',
    'peso': 70.0,
    'tipoSangre': 'O+',
    'telefono': 912345678,
    'elegibilidad': 'Apto',
    'fechaRetorno': null,
  };

  setUp(() async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  });

  tearDown(() async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  });

  group('Consulta y búsqueda de donantes (Task 3.1)', () {
    test(
      'Obtiene todos los donantes y busca por RUT normalizado o por nombre',
      () async {
        await DonanteRepository.guardarDonante(donanteBase('12.345.678-9'));
        await DonanteRepository.guardarDonante({
          ...donanteBase('98.765.432-1'),
          'nombre': 'María González',
        });

        final todos = await DonanteRepository.obtenerDonantes();
        expect(todos.length, 2);

        final porRut = await DonanteRepository.buscarDonantePorRut('123456789');
        expect(porRut, isNotNull);
        expect(porRut!['nombre'], 'Donante Prueba');

        final porNombre = await DonanteRepository.buscarDonantePorNombre(
          'maría',
        );
        expect(porNombre.length, 1);
        expect(porNombre.first['rut'], '98.765.432-1');
      },
    );
  });

  group('Actualización de donantes y elegibilidad (Task 3.1)', () {
    test('Test 1: Actualizar datos editables manteniendo RUT y tipoSangre intactos', () async {
      await DonanteRepository.guardarDonante(donanteBase('11.111.111-1'));

      final resultado = await DonanteRepository.actualizarDonante(
        '11.111.111-1',
        {
          'rut': '99.999.999-9',
          'tipoSangre': 'AB+',
          'telefono': 988887777,
          'peso': 82.5,
          'elegibilidad': 'Apto',
        },
      );

      expect(resultado['exito'], isTrue);

      final actualizado = await DonanteRepository.buscarDonantePorRut(
        '11.111.111-1',
      );
      expect(actualizado, isNotNull);
      expect(actualizado!['telefono'], 988887777);
      expect(actualizado['peso'], 82.5);
      expect(actualizado['rut'], '11.111.111-1');
      expect(actualizado['tipoSangre'], 'O+');
    });

    test('Test 2: Rechazar cambio a "Diferido temporalmente" sin fecha de habilitación', () async {
      await DonanteRepository.guardarDonante(donanteBase('22.222.222-2'));

      final resultado = await DonanteRepository.actualizarDonante(
        '22.222.222-2',
        {'elegibilidad': 'Diferido temporalmente'},
      );

      expect(resultado['exito'], isFalse);
      expect(
        resultado['mensaje'].toString().toLowerCase(),
        contains('obligatoria'),
      );
    });

    test('Test 3: Rechazar cambio a "Diferido temporalmente" con fecha pasada o actual', () async {
      await DonanteRepository.guardarDonante(donanteBase('33.333.333-3'));

      final hoy = DateTime.now();
      final resHoy = await DonanteRepository.actualizarDonante('33.333.333-3', {
        'elegibilidad': 'Diferido temporalmente',
        'fechaHabilitacion': hoy.toIso8601String(),
      });
      expect(resHoy['exito'], isFalse);
      expect(resHoy['mensaje'].toString().toLowerCase(), contains('futura'));

      final ayer = hoy.subtract(const Duration(days: 1));
      final resAyer = await DonanteRepository.actualizarDonante(
        '33.333.333-3',
        {
          'elegibilidad': 'Diferido temporalmente',
          'fechaHabilitacion': ayer.toIso8601String(),
        },
      );
      expect(resAyer['exito'], isFalse);
      expect(resAyer['mensaje'].toString().toLowerCase(), contains('futura'));
    });

    test('Test 4: Rechazar actualización de un donante que no existe en el registro', () async {
      expect(
        () => DonanteRepository.actualizarDonante('99.999.999-K', {
          'telefono': 955554444,
          'peso': 68.0,
          'elegibilidad': 'Apto',
        }),
        throwsStateError,
      );
    });
  });
}
