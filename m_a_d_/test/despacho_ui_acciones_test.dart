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
testWidgets(
        'Test 3: Cancela orden pendiente desde el diálogo y oculta botones',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaDespachoInteractiva(
              ordenInicial: {
                'id': 103,
                'sede_origen': 'Banco Concepción',
                'hospital_destino': 'Hospital Regional',
                'estado': 'Pendiente',
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancelar orden'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar orden de despacho'), findsOneWidget);

      await tester.tap(find.text('Confirmar cancelación'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('Pendiente'), findsNothing);
      expect(find.text('Editar destino'), findsNothing);
      expect(find.text('Cancelar orden'), findsNothing);
      expect(
        find.text('Orden cancelada y unidades liberadas al inventario.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Test 4: Confirma salida a ruta y bloquea ediciones posteriores',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaDespachoInteractiva(
              ordenInicial: {
                'id': 104,
                'sede_origen': 'Banco Concepción',
                'hospital_destino': 'Hospital Traumatológico',
                'estado': 'Pendiente',
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('En ruta'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar salida a ruta'), findsOneWidget);

      await tester.tap(find.text('Confirmar salida'));
      await tester.pumpAndSettle();

      expect(find.text('En ruta'), findsOneWidget);
      expect(find.text('Pendiente'), findsNothing);
      expect(find.text('Editar destino'), findsNothing);
      expect(find.text('Cancelar orden'), findsNothing);
      expect(
        find.text('Despacho marcado como "En ruta".'),
        findsOneWidget,
      );
    });
  });
}