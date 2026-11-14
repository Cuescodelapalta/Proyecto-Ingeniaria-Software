import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';
import 'package:m_a_d_/inventario_unidades_screen.dart';

void main() {
  const String testFilePath = 'unidades.json';

  group('Lógica de detección de unidades por vencer (Task 12)', () {
    final fechaBase = DateTime(2026, 11, 13);

    test('Retorna true si la unidad disponible vence hoy (0 días)', () {
      final unidad = {
        'estado': 'Disponible',
        'fecha_caducidad': '2026-11-13',
      };
      expect(
        UnidadRepository.estaPorVencer(unidad, fechaReferencia: fechaBase),
        isTrue,
      );
      expect(
        UnidadRepository.diasParaVencer('2026-11-13', fechaReferencia: fechaBase),
        0,
      );
    });

    test('Retorna true en el límite exacto de 7 días restantes', () {
      final unidad = {
        'estado': 'Disponible',
        'fecha_caducidad': '2026-11-20',
      };
      expect(
        UnidadRepository.estaPorVencer(unidad, fechaReferencia: fechaBase),
        isTrue,
      );
      expect(
        UnidadRepository.diasParaVencer('2026-11-20', fechaReferencia: fechaBase),
        7,
      );
    });

    test('Retorna false si faltan 8 días o más', () {
      final unidad = {
        'estado': 'Disponible',
        'fecha_caducidad': '2026-11-21',
      };
      expect(
        UnidadRepository.estaPorVencer(unidad, fechaReferencia: fechaBase),
        isFalse,
      );
    });

    test('Retorna false si la unidad ya está vencida o no está Disponible', () {
      final unidadYaVencida = {
        'estado': 'Vencida',
        'fecha_caducidad': '2026-11-10',
      };
      final unidadFechaPasada = {
        'estado': 'Disponible',
        'fecha_caducidad': '2026-11-12',
      };

      expect(
        UnidadRepository.estaPorVencer(unidadYaVencida, fechaReferencia: fechaBase),
        isFalse,
      );
      expect(
        UnidadRepository.estaPorVencer(unidadFechaPasada, fechaReferencia: fechaBase),
        isFalse,
      );
    });
  });

  group('Pruebas visuales (Widget Tests) de alerta por color en InventarioUnidadesScreen', () {
    testWidgets('Muestra alerta naranja para unidades por vencer y roja para vencidas',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final hoy = DateTime.now();
      final en3Dias = hoy.add(const Duration(days: 3));
      final hace5Dias = hoy.subtract(const Duration(days: 5));
      final en20Dias = hoy.add(const Duration(days: 20));

      String formatear(DateTime d) => d.toIso8601String().split('T').first;

      final datosPrueba = [
        {
          'id': 1,
          'rut_donante': '111111111',
          'tipo_sangre': 'O+',
          'estado': 'Disponible',
          'fecha_caducidad': formatear(en3Dias),
          'fecha_extraccion': formatear(hoy.subtract(const Duration(days: 39))),
          'volumen': 450,
          'sede': 'Concepción',
        },
        {
          'id': 2,
          'rut_donante': '222222222',
          'tipo_sangre': 'A-',
          'estado': 'Disponible',
          'fecha_caducidad': formatear(hace5Dias),
          'fecha_extraccion': formatear(hoy.subtract(const Duration(days: 47))),
          'volumen': 450,
          'sede': 'Talcahuano',
        },
        {
          'id': 3,
          'rut_donante': '333333333',
          'tipo_sangre': 'B+',
          'estado': 'Disponible',
          'fecha_caducidad': formatear(en20Dias),
          'fecha_extraccion': formatear(hoy.subtract(const Duration(days: 22))),
          'volumen': 450,
          'sede': 'Chiguayante',
        },
      ];

      await tester.runAsync(() async {
        await File(testFilePath).writeAsString(jsonEncode(datosPrueba));
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: InventarioUnidadesScreen(),
        ),
      );

      // Esperar activamente a que desaparezca el CircularProgressIndicator
      for (int i = 0; i < 20; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      expect(
        find.text('Alerta: 1 unidad por vencer en los próximos 7 días.'),
        findsOneWidget,
      );
      expect(find.text('Por vencer (3 d)'), findsOneWidget);

      // Apagar el switch "Solo disponibles"
      await tester.tap(find.byType(Switch));
      await tester.pump();

      for (int i = 0; i < 20; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      expect(find.text('Vencida'), findsNWidgets(2));

      await tester.runAsync(() async {
        final file = File(testFilePath);
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      });
    });
  });
}