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
}
