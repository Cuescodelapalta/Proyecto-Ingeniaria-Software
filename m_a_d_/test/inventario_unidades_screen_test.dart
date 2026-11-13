import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/inventario_unidades_screen.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';

void main() {
  const String testFilePath = 'unidades.json';

  // Helper seguro para limpiar el archivo de unidades evitando bloqueos en Windows
  Future<void> limpiarArchivo() async {
    final file = File(testFilePath);
    int intentos = 0;
    while (intentos < 5) {
      try {
        if (await file.exists()) {
          await file.writeAsString('[]');
        } else {
          await file.writeAsString('[]');
        }
        break;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
        intentos++;
      }
    }
  }

  setUp(() async {
    await limpiarArchivo();
  });

  tearDown(() async {
    await limpiarArchivo();
  });

  // Helper inteligente para esperar a que el CircularProgressIndicator termine de cargar sin hacer timeout
  Future<void> esperarCarga(WidgetTester tester) async {
    int intentos = 0;
    while (tester.any(find.byType(CircularProgressIndicator)) && intentos < 50) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      intentos++;
    }
  }

  group('Task 10 - Pruebas de Interfaz de Inventario (InventarioUnidadesScreen)', () {
    
    testWidgets('Test 1: Visualización del inventario con datos (Camino normal)', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await limpiarArchivo();
        await UnidadRepository.guardarUnidad(
          rutDonante: '123456742',
          tipoSangre: 'O-',
          fechaExtraccion: DateTime(2026, 11, 3),
          volumen: 450,
          sede: 'Sede A',
        );
      });

      await tester.pumpWidget(const MaterialApp(home: InventarioUnidadesScreen()));
      await esperarCarga(tester);

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Sede A'), findsOneWidget);
      expect(find.text('123456742'), findsOneWidget);
    });

    testWidgets('Test 2: Pantalla sin stock (Empty state)', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await limpiarArchivo();
      });

      await tester.pumpWidget(const MaterialApp(home: InventarioUnidadesScreen()));
      await esperarCarga(tester);

      expect(
        find.text('No hay unidades de sangre registradas\nque coincidan con los filtros.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('Test 3: Interacción con filtros en la UI', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await limpiarArchivo();
        await UnidadRepository.guardarUnidad(
          rutDonante: '123456742',
          tipoSangre: 'O-',
          fechaExtraccion: DateTime(2026, 11, 3),
          volumen: 450,
          sede: 'Sede A',
        );
        await UnidadRepository.guardarUnidad(
          rutDonante: '111111111',
          tipoSangre: 'A+',
          fechaExtraccion: DateTime(2026, 11, 5),
          volumen: 450,
          sede: 'Sede B',
        );
      });

      await tester.pumpWidget(const MaterialApp(home: InventarioUnidadesScreen()));
      await esperarCarga(tester);

      expect(find.text('Sede A'), findsOneWidget);
      expect(find.text('Sede B'), findsOneWidget);

      // Abrir el Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Seleccionar 'O-' del menú desplegable
      await tester.tap(find.text('O-').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Esperar dinámicamente a que termine la recarga asíncrona del filtro en disco
      await esperarCarga(tester);

      // Verificaciones finales del filtrado en la UI
      expect(find.text('Sede A'), findsOneWidget);
      expect(find.text('Sede B'), findsNothing);
    });
  });
}