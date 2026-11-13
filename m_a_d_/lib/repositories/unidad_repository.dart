import 'dart:convert';
import 'dart:io';

class UnidadRepository {
  static const String _filePath = 'unidades.json';

  static Future<bool> guardarUnidad({
    required String tipoSangre,
    required DateTime fechaExtraccion,
    required int volumen,
    required String sede,
  }) async {
    try {
      final file = File(_filePath);
      if (!await file.exists()) {
        await file.writeAsString(jsonEncode([]));
      }

      final List<dynamic> listaUnidades = jsonDecode(await file.readAsString());

      // Genera id entero autoincremental según el UML (id: int)
      final int nuevoId = listaUnidades.isEmpty
          ? 1
          : (listaUnidades.last['id'] as int) + 1;

      // Lógica central de la Task08:
      final DateTime fechaCaducidad = fechaExtraccion.add(const Duration(days: 42));
      const String estadoInicial = 'Disponible';

      final nuevaUnidad = {
        'id': nuevoId,
        'tipo_sangre': tipoSangre,
        'estado': estadoInicial,
        'fecha_caducidad': fechaCaducidad.toIso8601String().split('T').first,
        'fecha_extraccion': fechaExtraccion.toIso8601String().split('T').first,
        'volumen': volumen,
        'sede': sede,
      };

      listaUnidades.add(nuevaUnidad);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(listaUnidades),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}