import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/registro_donantes_screen.dart';

void main() {
  const String testFilePath = 'donantes.json';

  // Helper seguro para limpiar donantes.json evitando bloqueos en Windows
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

  group('RegistroDonanteScreen - Pruebas de Formulario y Elegibilidad (RF-11)', () {
    
    testWidgets('Muestra errores de validación si los campos obligatorios están vacíos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroDonanteScreen(),
        ),
      );
      await tester.pump();

      final botonGuardar = find.widgetWithText(ElevatedButton, 'Guardar');
      await tester.ensureVisible(botonGuardar);
      await tester.tap(botonGuardar);
      await tester.pump();

      expect(find.text('El RUT es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('La fecha de nacimiento es obligatoria'), findsOneWidget);
      expect(find.text('El peso es obligatorio'), findsOneWidget);
      expect(find.text('El teléfono es obligatorio'), findsOneWidget);
    });

    testWidgets('Muestra el campo condicional de fecha de retorno al seleccionar Diferido (RF-11)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroDonanteScreen(),
        ),
      );
      await tester.pump();

      // Seleccionar el estado de evaluación clínica 'Diferido' (segundo Dropdown)
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('Diferido').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Verificar que aparece el campo condicional de fecha de retorno exigido por RF-11
      expect(find.text('Fecha en que podrá volver a donar *'), findsOneWidget);

      final botonGuardar = find.widgetWithText(ElevatedButton, 'Guardar');
      await tester.ensureVisible(botonGuardar);
      await tester.tap(botonGuardar);
      await tester.pump();

      expect(find.text('Un donante diferido debe registrar cuándo podrá volver a donar.'), findsOneWidget);
    });

    testWidgets('Flujo completo: Registra un donante Apto exitosamente en la UI y persiste en donantes.json', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroDonanteScreen(),
        ),
      );
      await tester.pump();

      // Rellenar los campos de texto
      await tester.enterText(find.byType(TextFormField).at(0), '123456785'); // RUT
      await tester.enterText(find.byType(TextFormField).at(1), 'Juan Pérez'); // Nombre
      await tester.enterText(find.byType(TextFormField).at(2), '1995-05-12'); // Fecha Nacimiento
      await tester.enterText(find.byType(TextFormField).at(3), '75.5'); // Peso
      await tester.enterText(find.byType(TextFormField).at(4), '912345678'); // Teléfono

      // Seleccionar Tipo de Sangre ('O+') -> Primer Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('O+').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Seleccionar Estado Clínico ('Apto') -> Segundo Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('Apto').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final botonGuardar = find.widgetWithText(ElevatedButton, 'Guardar');
      await tester.ensureVisible(botonGuardar);

      await tester.runAsync(() async {
        await tester.tap(botonGuardar);
        await Future.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      // Verificar SnackBar verde de éxito
      expect(find.text('Información del donante guardada exitosamente'), findsOneWidget);

      // Verificar persistencia real en donantes.json
      final archivoDonantes = File(testFilePath);
      final existe = await tester.runAsync(() => archivoDonantes.exists());
      expect(existe, isTrue);

      final contenidoJson = await tester.runAsync(() => archivoDonantes.readAsString());
      final listaDonantes = jsonDecode(contenidoJson!) as List<dynamic>;

      expect(listaDonantes.length, 1);
      expect(listaDonantes.first['rut'], '123456785');
      expect(listaDonantes.first['nombre'], 'Juan Pérez');
      expect(listaDonantes.first['tipoSangre'], 'O+');
      expect(listaDonantes.first['elegibilidad'], 'Apto');
    });
  });
}