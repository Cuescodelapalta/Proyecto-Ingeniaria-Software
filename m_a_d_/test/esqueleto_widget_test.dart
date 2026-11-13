import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/esqueleto_page.dart';

void main() {
  testWidgets('Task02 (T01): El boton de esqueleto activa el SnackBar de exito', (WidgetTester tester) async {
    // Carga la pantalla en el entorno de pruebas
    await tester.pumpWidget(
      const MaterialApp(
        home: EsqueletoPage(),
      ),
    );

    // Encuentra el botón y simula el tap del usuario
    final boton = find.byType(ElevatedButton);
    expect(boton, findsOneWidget);
    await tester.tap(boton);

    // Renderizado del SnackBar
    await tester.pumpAndSettle();

    // Confirma que el mensaje de éxito apareció en pantalla
    expect(find.textContaining('RUT 1-9'), findsOneWidget);
  });
}