import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/orden_despacho.dart';
import 'package:m_a_d_/repositories/despacho_repository.dart';

void main() {
  const String ordenesPath = 'ordenes_despacho.json';
  const String unidadesPath = 'unidades.json';

  Future<void> borrarArchivos() async {
    for (final path in [ordenesPath, unidadesPath]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  setUp(borrarArchivos);
  tearDown(borrarArchivos);

  // Las unidades 1 y 2 pertenecen a la orden y la 3 es de otra.
  Future<void> crearUnidadesDespachadas() async {
    await File(unidadesPath).writeAsString(
      jsonEncode([
        for (final id in [1, 2, 3]) {'id': id, 'estado': 'Despachado'},
      ]),
    );
  }

  // Se usa la hora actual para que la orden este dentro de la ventana.
  Future<void> crearOrdenPendiente() async {
    await crearUnidadesDespachadas();
    await DespachoRepository.guardarOrden(
      OrdenDespacho(
        id: 1,
        fechaSolicitud: DateTime.now(),
        sedeOrigen: 'Sede Concepcion',
        centroMedicoDestino: 'Hospital Regional',
        unidadesIds: [1, 2],
      ),
    );
  }

  Future<Map<int, String>> estadosUnidades() async {
    final lista =
        jsonDecode(await File(unidadesPath).readAsString()) as List<dynamic>;
    return {for (final u in lista) u['id'] as int: u['estado'] as String};
  }

  Matcher lanzaNoModificableEnRuta() => throwsA(
    isA<DespachoNoModificableException>().having(
      (e) => e.mensaje,
      'mensaje',
      contains('en ruta'),
    ),
  );

  group('DespachoRepository - Task 6.1', () {
    test('se actualiza el destino de una orden "Pendiente" y mantiene las unidades despachadas', () async {
      await crearOrdenPendiente();

      await DespachoRepository.actualizarDestino(1, 'Hospital 1');

      final orden = await DespachoRepository.obtenerOrdenPorId(1);
      expect(orden!.centroMedicoDestino, 'Hospital 1');
      expect(orden.estado, 'Pendiente');
      expect(await estadosUnidades(), {
        1: 'Despachado',
        2: 'Despachado',
        3: 'Despachado',
      });
    });

    test('rechaza un destino vacio', () async {
      await crearOrdenPendiente();

      await expectLater(
        DespachoRepository.actualizarDestino(1, '   '),
        throwsArgumentError,
      );
    });

    test('cancelar una orden "Pendiente" la deja "Cancelada" y libera sus unidades', () async {
      await crearOrdenPendiente();
      await DespachoRepository.cancelarOrden(1);

      final orden = await DespachoRepository.obtenerOrdenPorId(1);
      expect(orden!.estado, 'Cancelada');
      expect(await estadosUnidades(), {
        1: 'Disponible',
        2: 'Disponible',
        3: 'Despachado',
      }); // la 3 no pertence a la orden por lo tanto sigue despachada.
    });

    test('la confirmacion manual pasa la orden a "En ruta"', () async {
      await crearOrdenPendiente();
      await DespachoRepository.confirmarSalida(1);

      final orden = await DespachoRepository.obtenerOrdenPorId(1);
      expect(orden!.estado, 'En ruta');
    });

    test(
      'al expirar la ventana de preparacion la orden pasa a "En ruta"',
      () async {
        await crearOrdenPendiente();
        final orden = await DespachoRepository.obtenerOrdenPorId(1);

        // Dentro de la ventana: no cambia nada.
        final antes = await DespachoRepository.transicionarOrdenesVencidas(
          ahora: orden!.fechaSolicitud.add(const Duration(minutes: 5)),
        );
        expect(antes, 0);
        expect(
          (await DespachoRepository.obtenerOrdenPorId(1))!.estado,
          'Pendiente',
        );

        // Pasada la ventana: cambia a En ruta.
        final despues = await DespachoRepository.transicionarOrdenesVencidas(
          ahora: orden.fechaSolicitud.add(
            DespachoRepository.ventanaPreparacion + const Duration(minutes: 1),
          ),
        );
        expect(despues, 1);
        expect(
          (await DespachoRepository.obtenerOrdenPorId(1))!.estado,
          'En ruta',
        );
      },
    );

    test('una orden "En ruta" no se puede editar ni cancelar', () async {
      await crearOrdenPendiente();
      await DespachoRepository.confirmarSalida(1);

      await expectLater(
        DespachoRepository.actualizarDestino(1, 'Otro Hospital'),
        lanzaNoModificableEnRuta(),
      );
      await expectLater(
        DespachoRepository.cancelarOrden(1),
        lanzaNoModificableEnRuta(),
      );

      final orden = await DespachoRepository.obtenerOrdenPorId(1);
      expect(orden!.centroMedicoDestino, 'Hospital Regional');
      expect(orden.estado, 'En ruta');
      expect((await estadosUnidades())[1], 'Despachado');
    });

    test('una orden "Cancelada" tampoco se puede modificar', () async {
      await crearOrdenPendiente();
      await DespachoRepository.cancelarOrden(1);

      await expectLater(
        DespachoRepository.actualizarDestino(1, 'Otro Hospital'),
        throwsA(isA<DespachoNoModificableException>()),
      );
      await expectLater(
        DespachoRepository.confirmarSalida(1),
        throwsA(isA<DespachoNoModificableException>()),
      );
    });

    test('falla si la orden no existe', () async {
      await expectLater(DespachoRepository.cancelarOrden(99), throwsStateError);
    });
  });
}
