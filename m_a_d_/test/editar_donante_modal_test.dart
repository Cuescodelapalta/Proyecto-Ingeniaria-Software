import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/editar_donante_modal.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

void main() {
  const String filePath = 'donantes.json';

  final Map<String, dynamic> donanteInicial = {
    'rut': '12.345.678-9',
    'nombre': 'Camila Soto',
    'fechaNacimiento': '1994-08-20',
    'peso': 65.0,
    'tipoSangre': 'A+',
    'telefono': 912345678,
    'elegibilidad': 'Apto',
    'fechaRetorno': null,
  };

  Future<void> limpiarArchivo() async {
    final file = File(filePath);
    for (var i = 0; i < 10; i++) {
      if (!await file.exists()) return;
      try {
        await file.delete();
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  setUp(() async {
    await limpiarArchivo();
    await DonanteRepository.guardarDonante(donanteInicial);
  });

  tearDown(() async {
    await limpiarArchivo();
  });

  /// Simula una vista de listado que abre el modal y refresca los datos al guardar.
  Widget buildListadoConEdicion(List<Map<String, dynamic>> donantesIniciales) {
    var donantes = List<Map<String, dynamic>>.from(donantesIniciales);

    return MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            final donante = donantes.first;
            return ListTile(
              title: Text('${donante['nombre']} - ${donante['elegibilidad']}'),
              subtitle: Text(
                'Tel: ${donante['telefono']} | Peso: ${donante['peso']} kg',
              ),
              trailing: IconButton(
                key: const Key('boton_abrir_edicion'),
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final guardado = await mostrarModalEditarDonante(
                    context,
                    donante,
                  );
                  if (guardado == true) {
                    final actualizados =
                        await DonanteRepository.obtenerDonantes();
                    setState(() => donantes = actualizados);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Presiona Guardar y espera en el bucle real de E/S de Windows hasta que
  /// DonanteRepository termine de escribir y el modal se cierre o muestre error.
  Future<void> presionarGuardarYEsperarIO(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.text('Editar Donante').evaluate().isEmpty ||
          find
              .byKey(const Key('mensaje_error_edicion'))
              .evaluate()
              .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('EditarDonanteModal (Task 3.3)', () {
    testWidgets(
      'Test 1: Guarda edición de teléfono (9 dígitos) y peso y refleja cambios en el listado',
      (tester) async {
        final iniciales = await tester.runAsync(
          () => DonanteRepository.obtenerDonantes(),
        );
        await tester.pumpWidget(buildListadoConEdicion(iniciales!));
        await tester.pumpAndSettle();

        expect(find.text('Tel: 912345678 | Peso: 65.0 kg'), findsOneWidget);

        await tester.tap(find.byKey(const Key('boton_abrir_edicion')));
        await tester.pumpAndSettle();

        expect(find.text('12.345.678-9'), findsOneWidget);
        expect(find.text('A+'), findsOneWidget);

        // Rechaza teléfono con menos de 9 dígitos
        await tester.enterText(
          find.byKey(const Key('campo_editar_telefono')),
          '12345',
        );
        await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
        await tester.pumpAndSettle();
        expect(find.text('Debe tener 9 dígitos'), findsOneWidget);

        // Guarda con valores válidos
        await tester.enterText(
          find.byKey(const Key('campo_editar_telefono')),
          '987654321',
        );
        await tester.enterText(
          find.byKey(const Key('campo_editar_peso')),
          '68.5',
        );

        await presionarGuardarYEsperarIO(tester);

        expect(find.text('Editar Donante'), findsNothing);
        expect(find.text('Tel: 987654321 | Peso: 68.5 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2: Bloquea guardado al seleccionar Diferido temporalmente sin fecha',
      (tester) async {
        final iniciales = await tester.runAsync(
          () => DonanteRepository.obtenerDonantes(),
        );
        await tester.pumpWidget(buildListadoConEdicion(iniciales!));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('boton_abrir_edicion')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('boton_fecha_retorno')), findsNothing);

        await tester.tap(find.byKey(const Key('dropdown_editar_elegibilidad')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Diferido temporalmente').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('boton_fecha_retorno')), findsOneWidget);

        await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mensaje_error_edicion')), findsOneWidget);
        expect(
          find.textContaining('fecha de habilitación futura'),
          findsOneWidget,
        );
        expect(find.text('Editar Donante'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3: Guarda donante como Diferido temporalmente con fecha futura y actualiza listado',
      (tester) async {
        final iniciales = await tester.runAsync(
          () => DonanteRepository.obtenerDonantes(),
        );
        await tester.pumpWidget(buildListadoConEdicion(iniciales!));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('boton_abrir_edicion')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dropdown_editar_elegibilidad')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Diferido temporalmente').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('boton_fecha_retorno')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await presionarGuardarYEsperarIO(tester);

        expect(find.text('Editar Donante'), findsNothing);
        expect(
          find.text('Camila Soto - Diferido temporalmente'),
          findsOneWidget,
        );

        final persistido = await tester.runAsync(
          () => DonanteRepository.buscarDonantePorRut('12.345.678-9'),
        );
        expect(persistido!['elegibilidad'], 'Diferido temporalmente');
        expect(persistido['fechaRetorno'], isNotNull);
      },
    );

    testWidgets(
      'Test 4: Rechaza fecha de habilitación pasada al diferir temporalmente (RF-11)',
      (tester) async {
        final iniciales = await tester.runAsync(
          () => DonanteRepository.obtenerDonantes(),
        );
        await tester.pumpWidget(buildListadoConEdicion(iniciales!));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('boton_abrir_edicion')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dropdown_editar_elegibilidad')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Diferido temporalmente').last);
        await tester.pumpAndSettle();

        // Abre el DatePicker e ingresa manualmente una fecha pasada
        await tester.tap(find.byKey(const Key('boton_fecha_retorno')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, '01/01/2020');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Intenta guardar y verifica el bloqueo de dominio de DonanteRepository
        await presionarGuardarYEsperarIO(tester);

        expect(find.byKey(const Key('mensaje_error_edicion')), findsOneWidget);
        expect(find.text('Editar Donante'), findsOneWidget);

        final persistido = await tester.runAsync(
          () => DonanteRepository.buscarDonantePorRut('12.345.678-9'),
        );
        expect(persistido!['elegibilidad'], 'Apto');
      },
    );
  });
}
