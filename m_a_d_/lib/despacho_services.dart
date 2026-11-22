import 'package:m_a_d_/repositories/unidad_repository.dart';

class DespachoService {
  static Future<List<Map<String,dynamic>>> obtenerUnidadesElegibles({
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
}
