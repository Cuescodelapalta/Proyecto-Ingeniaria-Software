import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/home_screen.dart';
import 'package:m_a_d_/registro_donantes_screen.dart';
import 'package:m_a_d_/registro_unidades_screen.dart';
import 'package:m_a_d_/inventario_unidades_screen.dart';

void main() {
  group('HomeScreen - Pruebas de Interfaz y Navegación', () {
    
    testWidgets('Muestra el título de la AppBar y los tres botones principales', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Verifica el título principal definido en la AppBar
      expect(find.text('CBS - Banco de Sangre'), findsOneWidget);

      // Verifica la presencia de las tres opciones de navegación de la interfaz
      expect(find.text('Registro donantes'), findsOneWidget);
      expect(find.text('Registrar nueva unidad'), findsOneWidget);
      expect(find.text('Revisar inventario'), findsOneWidget);
    });

    testWidgets('Navega correctamente a RegistroDonanteScreen al presionar el botón correspondiente', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.tap(find.text('Registro donantes'));
      await tester.pumpAndSettle(); // Espera la transición de la ruta

      // Comprueba que se cargó la pantalla de registro de donantes
      expect(find.byType(RegistroDonanteScreen), findsOneWidget);
    });

    testWidgets('Navega correctamente a RegistroUnidadesScreen al presionar el botón correspondiente', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.tap(find.text('Registrar nueva unidad'));
      await tester.pumpAndSettle();

      // Comprueba que se cargó la pantalla de registro de unidades
      expect(find.byType(RegistroUnidadesScreen), findsOneWidget);
    });

    testWidgets('Navega correctamente a InventarioUnidadesScreen al presionar el botón correspondiente', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.tap(find.text('Revisar inventario'));
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 300));

      // Esperar activamente a que desaparezca el CircularProgressIndicator de InventarioUnidadesScreen
      for (int i = 0; i < 20; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      // Comprueba que se cargó la pantalla de inventario
      expect(find.byType(InventarioUnidadesScreen), findsOneWidget);
    });
  });
}