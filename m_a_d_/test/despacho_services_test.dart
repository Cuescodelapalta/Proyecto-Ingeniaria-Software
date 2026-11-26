import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/despacho_services.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';
import 'package:m_a_d_/repositories/despacho_repository.dart';

void main() {
  const String testFilepath = 'unidades.json';
  const String testOrdenesPath = 'ordenes_despacho.json';

  setUp(() async {
    final file = File(testFilepath);
    final ordenesFile = File(testOrdenesPath);
    try {
      if (await file.exists()) {
        await file.writeAsString('[]');
      }
      if (await ordenesFile.exists()) {
        await ordenesFile.writeAsString('[]');
      }
    } catch (_) {}
  });

  tearDown(() async {
    final file = File(testFilepath);
    final ordenesFile = File(testOrdenesPath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
      if (await ordenesFile.exists()) {
        await ordenesFile.delete();
      }
    } catch (_) {}
  });

  group('DespachoService - Logica FEFO y validaciones', () {
    test(
      'Test 1: sugerirUnidadesFEFO prioriza las unidades más próximas a vencer',
      () async {
        final unidadesPrueba = [
          {
            'id': 1,
            'rut_donante': '111111111',
            'tipo_sangre': 'O+',
            'estado': 'Disponible',
            'fecha_caducidad': '2027-01-10',
            'fecha_extraccion': '2026-11-29',
            'volumen': 450,
            'sede': 'Concepción',
          },
          {
            'id': 2,
            'rut_donante': '222222222',
            'tipo_sangre': 'O+',
            'estado': 'Disponible',
            'fecha_caducidad': '2027-01-02',
            'fecha_extraccion': '2026-11-21',
            'volumen': 450,
            'sede': 'Concepción',
          },
          {
            'id': 3,
            'rut_donante': '333333333',
            'tipo_sangre': 'O+',
            'estado': 'Disponible',
            'fecha_caducidad': '2027-01-05',
            'fecha_extraccion': '2026-11-24',
            'volumen': 450,
            'sede': 'Concepción',
          },
        ];
        await File(testFilepath).writeAsString(jsonEncode(unidadesPrueba));

        final sugeridas = await DespachoService.sugerirUnidadesFEFO(
          sede: 'Concepción',
          tipoSangre: 'O+',
          cantidad: 2,
        );
        expect(sugeridas.length, 2);
        expect(sugeridas[0]['id'], 2);
        expect(sugeridas[1]['id'], 3);
      },
    );

    test('Test 2: obtenerUnidadesElegibles filtra por estado, sede y tipo de sangre', () async {
      final unidadesPrueba = [
        {
          'id': 1,
          'rut_donante': '111111111',
          'tipo_sangre': 'O+',
          'estado': 'Vencida',
          'fecha_caducidad': '2027-01-02',
          'fecha_extraccion': '2026-11-21',
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 2,
          'rut_donante': '222222222',
          'tipo_sangre': 'O+',
          'estado': 'Despachado',
          'fecha_caducidad': '2027-01-03',
          'fecha_extraccion': '2026-11-22',
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 3,
          'rut_donante': '333333333',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-04',
          'fecha_extraccion': '2026-11-23',
          'volumen': 450,
          'sede': 'Talcahuano',
        },
        {
          'id': 4,
          'rut_donante': '444444444',
          'tipo_sangre': 'A-',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-05',
          'fecha_extraccion': '2026-11-24',
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 5,
          'rut_donante': '555555555',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-06',
          'fecha_extraccion': '2026-11-25',
          'volumen': 450,
          'sede': 'Concepción',
        },
      ];
      await File(testFilepath).writeAsString(jsonEncode(unidadesPrueba));
      final elegibles = await DespachoService.obtenerUnidadesElegibles(
        sede: 'Concepción',
        tipoSangre: 'O+',
      );

      expect(elegibles.length, 1);
      expect(elegibles.first['id'], 5);
    });

    test('Test 3: ejecutarDespacho guarda la orden y actualiza solo las unidades despachadas', () async {
      final unidadesPrueba = [
        {
          'id': 1,
          'rut_donante': '111111111',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-10',
          'fecha_extraccion': '2026-11-29',
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 2,
          'rut_donante': '222222222',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-12',
          'fecha_extraccion': '2026-12-01',
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 3,
          'rut_donante': '333333333',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-15',
          'fecha_extraccion': '2026-12-04',
          'volumen': 450,
          'sede': 'Talcahuano',
        },
      ];
      await File(testFilepath).writeAsString(jsonEncode(unidadesPrueba));

      final orden = await DespachoService.ejecutarDespacho(
        sede: 'Concepción',
        destino: 'Hospital Regional',
        unidadesIds: [1, 2],
      );

      expect(orden.id, 1);
      expect(orden.estado, 'Pendiente');
      expect(orden.sedeOrigen,'Concepción');
      expect(orden.centroMedicoDestino, 'Hospital Regional');
      expect(orden.unidadesIds, [1,2]);

      final ordenesGuardadas=await DespachoRepository.obtenerOrdenes();
      expect(ordenesGuardadas.length, 1);
      expect(ordenesGuardadas.first.id, 1);

      final unidadesActualizadas= await UnidadRepository.obtenerUnidades();
      final u1=unidadesActualizadas.firstWhere((u)=>u['id']==1);
      final u2=unidadesActualizadas.firstWhere((u)=>u['id']==2);
      final u3=unidadesActualizadas.firstWhere((u)=>u['id']==3);

      expect(u1['estado'], 'Despachado/a');
      expect(u2['estado'], 'Despachado/a');
      expect(u3['estado'], 'Disponible');
    });

    test('Test 4: sugerirUnidadesFEFO lanza excepción con stock insuficiente o cantidad invalida', () async {
      final unidadesPrueba = [
        {
          'id': 1,
          'rut_donante': '111111111',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': '2027-01-10',
          'fecha_extraccion': '2026-11-29',
          'volumen': 450,
          'sede': 'Concepción',
        },
      ];

      await File(testFilepath).writeAsString(jsonEncode(unidadesPrueba));
      await expectLater(
        () => DespachoService.sugerirUnidadesFEFO(
          sede: 'Concepción',
          tipoSangre: 'O+',
          cantidad: 2,
        ),
        throwsException,
      );
      await expectLater(
        () => DespachoService.sugerirUnidadesFEFO(
          sede: 'Concepción',
          tipoSangre: 'O+',
          cantidad: 0,
        ),
        throwsException,
      );
    });
  });
}
