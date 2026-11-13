import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/pages/unidad_sangre_page.dart';

void main() {
  const String filePath = 'inventario_sangre.json';

  setUp(() async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  });

  tearDown(() async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  });

  testWidgets('Task07: Presionar botón guarda una unidad de sangre', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnidadSangrePage(),
        ),
      );

    expect(find.text('Guardar unidad de prueba'), findsOneWidget);
      // Ejecuta el tap y espera el I/O real de archivos
      await tester.runAsync(() async {
        await tester.tap(find.text('Guardar unidad de prueba'));
        await Future.delayed(const Duration(milliseconds: 500));
      });

      // renderiza el SnackBar
      await tester.pumpAndSettle();
      expect(find.text('Unidad de sangre guardada correctamente.'), findsOneWidget);

      // Verifica el archivo también dentro de runAsync
      final existe = await tester.runAsync(() => File(filePath).exists());
      expect(existe, isTrue);
    },
  );
}