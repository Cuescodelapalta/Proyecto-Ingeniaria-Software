import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/lista_donantes_screen.dart';

void main() {
  const filePath = 'donantes.json';
  final file = File(filePath);
  String? contenidoOriginal;
  var archivoExistia = false;

  setUp(() async {
    archivoExistia = await file.exists();
    if (archivoExistia) {
      contenidoOriginal = await file.readAsString();
    }
  });

  tearDown(() async {
    if (archivoExistia) {
      await file.writeAsString(contenidoOriginal!);
    } else if (await file.exists()) {
      await file.delete();
    }
  });

  testWidgets('muestra el nombre y el RUT de cada donante', (tester) async {
    await tester.runAsync(
      () => file.writeAsString(
        jsonEncode([
          {'nombre': 'Ana Pérez', 'rut': '123456785'},
        ]),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ListaDonantesScreen()));

    var intentos = 0;
    while (tester.any(find.byType(CircularProgressIndicator)) &&
        intentos < 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      intentos++;
    }

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('RUT: 123456785'), findsOneWidget);
  });

  testWidgets('muestra los datos al seleccionar un donante', (tester) async {
    await tester.runAsync(
      () => file.writeAsString(
        jsonEncode([
          {
            'nombre': 'Ana Pérez',
            'rut': '123456785',
            'fechaNacimiento': '2000-01-01',
            'peso': 70.0,
            'tipoSangre': 'O+',
            'telefono': 912345678,
            'elegibilidad': 'Apto',
            'fechaRetorno': null,
          },
        ]),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ListaDonantesScreen()));

    var intentos = 0;
    while (tester.any(find.byType(CircularProgressIndicator)) &&
        intentos < 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      intentos++;
    }

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('RUT: 123456785'), findsOneWidget);

    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();

    expect(find.text('Fecha de nacimiento'), findsOneWidget);
    expect(find.text('2000-01-01'), findsOneWidget);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('70.0 kg'), findsOneWidget);
    expect(find.text('Tipo de sangre'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('912345678'), findsOneWidget);
    expect(find.text('Elegibilidad'), findsOneWidget);
    expect(find.text('Apto'), findsOneWidget);
  });

  testWidgets('filtra donantes en vivo por RUT ignorando puntos y guion', (
    tester,
  ) async {
    await tester.runAsync(
      () => file.writeAsString(
        jsonEncode([
          {'nombre': 'Ana Pérez', 'rut': '12.345.678-5'},
          {'nombre': 'Luis Soto', 'rut': '98.765.432-1'},
        ]),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ListaDonantesScreen()));

    var intentos = 0;
    while (tester.any(find.byType(CircularProgressIndicator)) &&
        intentos < 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      intentos++;
    }

    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Soto'), findsNothing);
  });

  testWidgets('muestra opción de registro cuando el RUT no coincide', (
    tester,
  ) async {
    await tester.runAsync(
      () => file.writeAsString(
        jsonEncode([
          {'nombre': 'Ana Pérez', 'rut': '123456785'},
        ]),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ListaDonantesScreen()));

    var intentos = 0;
    while (tester.any(find.byType(CircularProgressIndicator)) &&
        intentos < 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      intentos++;
    }

    await tester.enterText(find.byType(TextField), '999999999');
    await tester.pump();

    expect(
      find.text('No se encontraron donantes para ese RUT.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Registrar donante'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar nuevo donante'), findsOneWidget);
  });
}
