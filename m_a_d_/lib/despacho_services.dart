import 'package:m_a_d_/repositories/despacho_repository.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';
import 'package:m_a_d_/orden_despacho.dart';

class DespachoService {
  static Future<List<Map<String, dynamic>>> obtenerUnidadesElegibles({
    required String sede,
    required String tipoSangre,
  }) async {
    final inventario = await UnidadRepository.obtenerUnidades();

    final elegibles = inventario.where((u) {
      final mismaSede =
          (u['sede'] ?? '').toString().trim().toLowerCase() ==
          sede.trim().toLowerCase();
      final mismoTipo = u['tipo_sangre'] == tipoSangre;
      final disponible = u['estado'] == 'Disponible';
      return mismaSede && mismoTipo && disponible;
    }).toList();

    elegibles.sort((a, b) {
      final fechaA = DateTime.parse(a['fecha_caducidad'] as String);
      final fechaB = DateTime.parse(b['fecha_caducidad'] as String);
      return fechaA.compareTo(fechaB);
    });
    return elegibles;
  }

  static Future<List<Map<String, dynamic>>> sugerirUnidadesFEFO({
    required String sede,
    required String tipoSangre,
    required int cantidad,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }
    final elegibles = await obtenerUnidadesElegibles(
      sede: sede,
      tipoSangre: tipoSangre,
    );
    if (elegibles.length < cantidad) {
      throw Exception('El stock disponible no es suficiente');
    }
    return elegibles.take(cantidad).toList();
  }

  static Future<OrdenDespacho> ejecutarDespacho({
    required String sede,
    required String destino,
    required List<int> unidadesIds,
  }) async {
    if (sede.trim().isEmpty || destino.trim().isEmpty) {
      throw Exception(
        'La sede de origen y el centro medico de destino son obligatorios',
      );
    }
    if (unidadesIds.isEmpty) {
      throw Exception(
        'No se puede realizar un despacho sin seleccionar unidades',
      );
    }
    if (unidadesIds.length != unidadesIds.toSet().length) {
      throw Exception('No se puede seleccionar más de una vez la misma unidad');
    }
    final inventario = await UnidadRepository.obtenerUnidades();
    for (final id in unidadesIds) {
      final encontradas = inventario.where((u) => u['id'] == id).toList();
      if (encontradas.isEmpty) {
        throw Exception('La unidad $id no existe en el inventario');
      }
      final unidad = encontradas.first;
      if (unidad['estado'] != 'Disponible') {
        throw Exception('La unidad $id no esta disponible');
      }
      final sedeUnidad = (unidad['sede'] ?? '').toString().trim().toLowerCase();
      if (sedeUnidad != sede.trim().toLowerCase()) {
        throw Exception('La unidad $id no pertenece a la sede $sede');
      }
    }
    final ordenesActuales = await DespachoRepository.obtenerOrdenes();
    final int nuevoId = ordenesActuales.isEmpty
        ? 1
        : ordenesActuales.last.id + 1;
    final nuevaOrden = OrdenDespacho(
      id: nuevoId,
      fechaSolicitud: DateTime.now(),
      sedeOrigen: sede.trim(),
      centroMedicoDestino: destino.trim(),
      unidadesIds: unidadesIds,
    );
    final resultado = await UnidadRepository.actualizarEstadoUnidades(
      ids: unidadesIds,
      nuevoEstado: 'Despachado/a',
    );
    if (!resultado) {
      throw Exception('No se pudo cambiar el estado de las unidades');
    }
    try {
      await DespachoRepository.guardarOrden(nuevaOrden);
    } catch (e) {
      await UnidadRepository.actualizarEstadoUnidades(
        ids: unidadesIds,
        nuevoEstado: 'Disponible',
      );
      throw Exception('Error al guardar la orden de despacho $e');
    }
    return nuevaOrden;
  }
}
