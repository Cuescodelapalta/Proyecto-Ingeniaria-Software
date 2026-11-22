import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/widgets/despacho_acciones_ui.dart';

void main() {
  group('Task 6.3 - Implementar modal de edición de destino y flujo de cancelación/salida en UI', () {
    testWidgets(
        'Test 1: Edita hospital de destino y refleja el cambio en la ruta',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaDespachoInteractiva(
              ordenInicial: {
                'id': 101,
                'sede_origen': 'Banco Concepción',
                'hospital_destino': 'Hospital Regional',
                'estado': 'Pendiente',
              },
            ),
          ),
        ),
      );

      expect(
        find.text('Banco Concepción → Hospital Regional'),
        findsOneWidget,
      );

      await tester.tap(find.text('Editar destino'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'Clínica Biobío',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Banco Concepción → Clínica Biobío'),
        findsOneWidget,
      );
      expect(
        find.text('Destino del despacho actualizado correctamente.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Test 2: Rechaza edición de destino con campo vacío y mantiene el modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaDespachoInteractiva(
              ordenInicial: {
                'id': 102,
                'sede_origen': 'Banco Concepción',
                'hospital_destino': 'Hospital Higueras',
                'estado': 'Pendiente',
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Editar destino'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El destino es obligatorio'), findsOneWidget);
      expect(find.text('Editar hospital de destino'), findsOneWidget);
    });
  });
}