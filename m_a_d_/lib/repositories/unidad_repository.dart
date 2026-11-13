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

      final int nuevoId = listaUnidades.isEmpty
          ? 1
          : (listaUnidades.last['id'] as int) + 1;

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
static Future<List<Map<String, dynamic>>> obtenerUnidades() async {
  try{
    final file = File(_filePath);
    if(!await file.exists()){
      return [];
    }
    final String contenido = await file.readAsString();
    final List<dynamic> datos = jsonDecode(contenido);
    return datos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e){
    return [];
  }
}

/// filtra las unidades por estado y tipo de sangre, y las ordena por 
  /// la fecha de caducidad mas proxima (FEFO).
static Future<List<Map<String, dynamic>>> filtrarUnidades({
    String? tipoSangre,
    bool soloDisponibles = true,
  }) async {
List<Map<String, dynamic>> unidades = await obtenerUnidades();

    //filtra solo las que estan disponibles en inventario
    if (soloDisponibles) {
      unidades = unidades.where((u) => u['estado'] == 'Disponible').toList();
    }

    // 2. Filtrar por grupo sanguíneo específico (si se solicita)
    if (tipoSangre != null && tipoSangre.trim().isNotEmpty && tipoSangre != 'Todos') {
      unidades = unidades.where((u) => u['tipo_sangre'] == tipoSangre).toList();
    }

    // 3. Ordenar por caducidad (las más prontas a vencer quedan primero)
    unidades.sort((a, b) {
      final fechaA = DateTime.parse(a['fecha_caducidad'] as String);
      final fechaB = DateTime.parse(b['fecha_caducidad'] as String);
      return fechaA.compareTo(fechaB);
    });

    return unidades;
  }









}