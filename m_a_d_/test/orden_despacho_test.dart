import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/orden_despacho.dart';

void main() {
  group('OrdenDespacho', () {
    test('usa Pendiente como estado inicial y conserva los IDs recibidos', () {
      final ids = [12, 15];
      final orden = OrdenDespacho(
        id: 1,
        fechaSolicitud: DateTime(2026, 11, 24, 16, 30),
        sedeOrigen: 'Sede Central',
        centroMedicoDestino: 'Hospital Regional',
        unidadesIds: ids,
      );
      ids.add(18);

      expect(orden.estado, 'Pendiente');
      expect(orden.unidadesIds, [12, 15]);
    });

    test('serializa y reconstruye todos los campos', () {
      final orden = OrdenDespacho(
        id: 4,
        fechaSolicitud: DateTime(2026, 11, 24, 16, 30),
        sedeOrigen: 'Sede Central',
        centroMedicoDestino: 'Hospital Regional',
        unidadesIds: [12, 15],
      );

      final json = orden.toJson();
      final reconstruida = OrdenDespacho.fromJson(json);

      expect(json['estado'], 'Pendiente');
      expect(json['fecha_solicitud'], '2026-11-24T16:30:00.000');
      expect(json['unidades_ids'], [12, 15]);
      expect(reconstruida.id, orden.id);
      expect(reconstruida.fechaSolicitud, orden.fechaSolicitud);
      expect(reconstruida.sedeOrigen, orden.sedeOrigen);
      expect(reconstruida.centroMedicoDestino, orden.centroMedicoDestino);
      expect(reconstruida.estado, orden.estado);
      expect(reconstruida.unidadesIds, orden.unidadesIds);
    });
  });
}
