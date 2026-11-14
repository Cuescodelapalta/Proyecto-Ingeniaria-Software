import 'dart:convert';
import 'dart:io';

class UnidadRepository {
  static const String _filePath = 'unidades.json';

  static Future<bool> guardarUnidad({
    required String rutDonante,
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

      final DateTime fechaCaducidad = fechaExtraccion.add(
        const Duration(days: 42),
      );
      const String estadoInicial = 'Disponible';

      final nuevaUnidad = {
        'id': nuevoId,
        'rut_donante': rutDonante,
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
    try {
      await actualizarVencimientos();
      final file = File(_filePath);
      if (!await file.exists()) {
        return [];
      }
      final String contenido = await file.readAsString();
      final List<dynamic> datos = jsonDecode(contenido);
      return datos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
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
    if (tipoSangre != null &&
        tipoSangre.trim().isNotEmpty &&
        tipoSangre != 'Todos') {
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

  static Future<void> actualizarVencimientos() async {
    final file = File(_filePath);
    if (!await file.exists()) return;

    final String contenido = await file.readAsString();
    if (contenido.trim().isEmpty) return;

    List<dynamic> unidades = jsonDecode(contenido);
    bool cambio = false;
    final hoy = DateTime.now();
    final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);

    for (var i = 0; i < unidades.length; i++) {
      final unidad = unidades[i];
      if (unidad['estado'] == 'Disponible') {
        final caducidad = DateTime.parse(unidad['fecha_caducidad']);
        final fechaCaducidad = DateTime(
          caducidad.year,
          caducidad.month,
          caducidad.day,
        );

        if (fechaCaducidad.isBefore(fechaActual)) {
          unidades[i]['estado'] = 'Vencida';
          cambio = true;
        }
      }
    }
    if (cambio) {
      await file.writeAsString(
        const JsonEncoder.withIndent(' ').convert(unidades),
      );
    }
  }
  /// calcula dias calendario restantes hasta la fecha de vencimiento.
  static int diasParaVencer(
    String fechaCaducidadStr, {
    DateTime? fechaReferencia,
  }) {
    final hoy = fechaReferencia ?? DateTime.now();
    final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);
    final caducidad = DateTime.parse(fechaCaducidadStr);
    final fechaCaducidad = DateTime(
      caducidad.year,
      caducidad.month,
      caducidad.day,
    );
    return fechaCaducidad.difference(fechaActual).inDays;
  }

  /// Determina si una unidad disponible vence en 7 días o menos (Task12).
  static bool estaPorVencer(
    Map<String, dynamic> unidad, {
    int diasAlerta = 7,
    DateTime? fechaReferencia,
  }) {
    if (unidad['estado'] != 'Disponible') return false;
    final String? fechaStr = unidad['fecha_caducidad'] as String?;
    if (fechaStr == null || fechaStr.isEmpty) return false;

    final int diasRestantes = diasParaVencer(
      fechaStr,
      fechaReferencia: fechaReferencia,
    );
    return diasRestantes >= 0 && diasRestantes <= diasAlerta;
  }
}
