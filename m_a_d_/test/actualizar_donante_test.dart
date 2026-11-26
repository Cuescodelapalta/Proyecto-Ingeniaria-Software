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

  // Cobertura US03 (Task 3.1): CA1 (consulta/actualización), CA2 (no encontrado), CA3 (diferido temporal RF-11)
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

    test(
      'Retorna null o lista vacía cuando el RUT o nombre no existen',
      () async {
        await DonanteRepository.guardarDonante(donanteBase('12.345.678-9'));

        final rutInexistente = await DonanteRepository.buscarDonantePorRut(
          '11.111.111-1',
        );
        expect(rutInexistente, isNull);

        final rutVacio = await DonanteRepository.buscarDonantePorRut('   ');
        expect(rutVacio, isNull);

        final nombreInexistente =
            await DonanteRepository.buscarDonantePorNombre('Pedro');
        expect(nombreInexistente, isEmpty);
      },
    );
  });

  group('Actualización de donantes y elegibilidad', () {
    test(
      'Test 1: Actualiza datos editables manteniendo RUT y tipoSangre intactos',
      () async {
        await DonanteRepository.guardarDonante(donanteBase('11.111.111-1'));

        final resultado = await DonanteRepository.actualizarDonante(
          '11.111.111-1',
          {
            'rut': '99.999.999-9',
            'tipoSangre': 'AB+',
            'nombre': 'Juan Actualizado',
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
        expect(actualizado!['nombre'], 'Juan Actualizado');
        expect(actualizado['telefono'], 988887777);
        expect(actualizado['peso'], 82.5);
        expect(actualizado['rut'], '11.111.111-1');
        expect(actualizado['tipoSangre'], 'O+');
      },
    );

    test(
      'Test 2: Rechaza cambio a "Diferido temporalmente" sin fecha de habilitación',
      () async {
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
      },
    );

    test(
      'Test 3: Exige fecha futura al diferir temporalmente y limpia la fecha al volver a Apto',
      () async {
        await DonanteRepository.guardarDonante(donanteBase('33.333.333-3'));

        final hoy = DateTime.now();

        // Fecha actual (hoy) -> rechaza
        final resHoy = await DonanteRepository.actualizarDonante(
          '33.333.333-3',
          {
            'elegibilidad': 'Diferido temporalmente',
            'fechaRetorno': hoy.toIso8601String(),
          },
        );
        expect(resHoy['exito'], isFalse);
        expect(resHoy['mensaje'].toString().toLowerCase(), contains('futura'));

        // Fecha pasada (ayer) -> rechaza
        final ayer = hoy.subtract(const Duration(days: 1));
        final resAyer = await DonanteRepository.actualizarDonante(
          '33.333.333-3',
          {
            'elegibilidad': 'Diferido temporalmente',
            'fechaRetorno': ayer.toIso8601String(),
          },
        );
        expect(resAyer['exito'], isFalse);
        expect(resAyer['mensaje'].toString().toLowerCase(), contains('futura'));

        // Fecha futura (+15 días) -> acepta y persiste
        final futura = hoy.add(const Duration(days: 15));
        final resFutura = await DonanteRepository.actualizarDonante(
          '33.333.333-3',
          {
            'elegibilidad': 'Diferido temporalmente',
            'fechaRetorno': futura.toIso8601String(),
          },
        );
        expect(resFutura['exito'], isTrue);

        final diferido = await DonanteRepository.buscarDonantePorRut(
          '33.333.333-3',
        );
        expect(diferido!['elegibilidad'], 'Diferido temporalmente');
        expect(diferido['fechaRetorno'], isNotNull);

        // Volver a Apto -> limpia la fecha de retorno
        final resApto = await DonanteRepository.actualizarDonante(
          '33.333.333-3',
          {'elegibilidad': 'Apto'},
        );
        expect(resApto['exito'], isTrue);

        final apto = await DonanteRepository.buscarDonantePorRut(
          '33.333.333-3',
        );
        expect(apto!['elegibilidad'], 'Apto');
        expect(apto['fechaRetorno'], isNull);
      },
    );

    test(
      'Test 4: Rechazar actualización de un donante que no existe en el registro',
      () async {
        expect(
          () => DonanteRepository.actualizarDonante('99.999.999-K', {
            'telefono': 955554444,
            'peso': 68.0,
            'elegibilidad': 'Apto',
          }),
          throwsStateError,
        );
      },
    );
  });
}