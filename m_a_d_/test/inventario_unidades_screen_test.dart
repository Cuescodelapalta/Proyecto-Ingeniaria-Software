import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/registro_unidades_screen.dart';

void main() {
  const String testFileDonantes = 'donantes.json';
  const String testFileUnidades = 'unidades.json';

  // Helper seguro para limpiar archivos evitando bloqueos en Windows
  Future<void> limpiarArchivos() async {
    for (var path in [testFileDonantes, testFileUnidades]) {
      final file = File(path);
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
  }

  setUp(() async {
    await limpiarArchivos();
  });

  tearDown(() async {
    await limpiarArchivos();
  });

  group('RegistroUnidadesScreen - Pruebas de Formulario y Validaciones', () {
    
    testWidgets('Muestra errores de validación si los campos están vacíos', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroUnidadesScreen(),
        ),
      );
      await tester.pump();

      // Presionar directamente el botón de guardar sin rellenar nada
      final botonGuardar = find.byType(FilledButton);
      expect(botonGuardar, findsOneWidget);
      await tester.tap(botonGuardar);
      await tester.pump();

      // Verificar mensajes de error de los validadores
      expect(find.text('Completa este campo'), findsOneWidget); // RUT
      expect(find.text('Selecciona una fecha'), findsOneWidget); // Fecha de extracción
      expect(find.text('Ingresé la sede de donación'), findsOneWidget); // Sede
      expect(find.text('Ingresa una cantidad mayor que 0'), findsOneWidget); // Volumen
    });

    testWidgets('Valida formato y dígito verificador del RUT chileno', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroUnidadesScreen(),
        ),
      );
      await tester.pump();

      // Ingresar un RUT con dígito verificador incorrecto
      final finderRut = find.byType(TextFormField).first;
      await tester.enterText(finderRut, '12345678K');
      
      // Presionar guardar para disparar validadores
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('El dígito verificador del RUT no es válido'), findsOneWidget);
    });

    testWidgets('Flujo completo: Registra una unidad de sangre exitosamente con donante Apto', (WidgetTester tester) async {
      // Preparar un donante válido en donantes.json
      await tester.runAsync(() async {
        await File(testFileDonantes).writeAsString(
          jsonEncode([
            {
              'rut': '12345678-5',
              'elegibilidad': 'Apto',
              'tipoSangre': 'O+',
            }
          ]),
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RegistroUnidadesScreen(),
        ),
      );
      await tester.pump();

      // Rellenar el formulario
      await tester.enterText(find.byType(TextFormField).at(0), '123456785'); // RUT
      await tester.enterText(find.byType(TextFormField).at(2), 'Concepción Central'); // Sede
      await tester.enterText(find.byType(TextFormField).at(3), '450'); // Volumen

      // Abrir el selector de fecha (DatePicker)
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // Esperar animación del diálogo

      // Confirmar la fecha (compatible con 'OK' o 'Aceptar')
      final okButton = find.text('OK');
      final aceptarButton = find.text('Aceptar');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
      } else if (aceptarButton.evaluate().isNotEmpty) {
        await tester.tap(aceptarButton);
      }
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // Esperar cierre del diálogo

      // Presionar el botón de guardar dentro de runAsync por el I/O de archivos
      await tester.runAsync(() async {
        await tester.tap(find.byType(FilledButton));
        await Future.delayed(const Duration(milliseconds: 400));
      });

      await tester.pump();

      // Verificaciones de éxito
      expect(find.textContaining('Unidad procesada con éxito'), findsOneWidget);

      // Comprobar persistencia en unidades.json
      final archivoUnidades = File(testFileUnidades);
      final existe = await tester.runAsync(() => archivoUnidades.exists());
      expect(existe, isTrue);

      final contenidoJson = await tester.runAsync(() => archivoUnidades.readAsString());
      final contenido = jsonDecode(contenidoJson!) as List<dynamic>;
      
      expect(contenido.length, 1);
      expect(contenido.first['rut_donante'], '123456785');
      expect(contenido.first['tipo_sangre'], 'O+');
      expect(contenido.first['volumen'], 450);
      expect(contenido.first['sede'], 'Concepción Central');
    });
  });
}