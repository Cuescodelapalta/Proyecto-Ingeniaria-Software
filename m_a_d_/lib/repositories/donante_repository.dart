import 'dart:convert';
import 'dart:io';

class DonanteRepository {
  static const String _filePath = 'donantes.json';

  static Future<bool> guardarDonanteEsqueleto() async {
    try {
      final file = File(_filePath);

      if (!await file.exists()) {
        await file.writeAsString(jsonEncode([]));
      }

      final String contenido = await file.readAsString();
      List<dynamic> listaDonantes = jsonDecode(contenido);

      final registroFijo = {
        'rut': '1-9',
        'nombre': 'Donante Prueba Esqueleto',
        'fechaNacimiento': '2000-01-01',
        'peso': 70.0,
        'tipoSangre': 'O+',
        'telefono': 912345678,
        'elegibilidad': 'Apto',
        'fechaRetorno': null,
      };

      listaDonantes.add(registroFijo);

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(listaDonantes),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deja el RUT en formato comparable, sin puntos ni guion y en mayúscula
  static String normalizarRut(String rut) =>
      rut.trim().replaceAll(RegExp(r'[.-]'), '').toUpperCase();

  /// Lee donantes.json. Si no existe o está vacío, devuelve una lista vacía.
  static Future<List<dynamic>> _leerDonantes() async {
    final file = File(_filePath);
    if (!await file.exists()) return [];

    final contenido = await file.readAsString();
    if (contenido.trim().isEmpty) return [];

    final dynamic datos = jsonDecode(contenido);
    if (datos is! List) {
      throw const FormatException(
        'donantes.json no contiene una lista válida.',
      );
    }
    return datos;
  }

  static bool _contieneRut(List<dynamic> donantes, String rut) {
    final buscado = normalizarRut(rut);
    return donantes.any((d) =>
        d is Map &&
        d['rut'] is String &&
        normalizarRut(d['rut'] as String) == buscado);
  }

  /// true si el RUT ya está registrado en donantes.json.
  static Future<bool> existeRut(String rut) async {
    return _contieneRut(await _leerDonantes(), rut);
  }

  /// Guarda un donante solo si su RUT no existe ya en donantes.json
  static Future<Map<String, Object>> guardarDonante(
      Map<String, dynamic> donante) async {
    try {
      final rut = donante['rut'];
      if (rut is! String || rut.trim().isEmpty) {
        return {'exito': false, 'mensaje': 'El donante debe tener un RUT.'};
      }

      const estadosEvaluacion = {'Apto', 'Diferido', 'Rechazado'};
      final elegibilidad = donante['elegibilidad'];
      if (elegibilidad is! String ||
          !estadosEvaluacion.contains(elegibilidad)) {
        return {
          'exito': false,
          'mensaje': 'La elegibilidad debe ser Apto, Diferido o Rechazado.',
        };
      }

      // Validación RF-11: Si es diferido temporalmente, debe registrar cuándo podrá volver a donar[cite: 8]
      if (elegibilidad == 'Diferido') {
        final fechaRetorno = donante['fechaRetorno'];
        if (fechaRetorno == null || (fechaRetorno is String && fechaRetorno.trim().isEmpty)) {
          return {
            'exito': false,
            'mensaje': 'Un donante diferido debe registrar cuándo podrá volver a donar.',
          };
        }
      }

      final donantes = await _leerDonantes();

      if (_contieneRut(donantes, rut)) {
        return {
          'exito': false,
          'mensaje': 'RUT duplicado: el RUT $rut ya está registrado.',
        };
      }

      donantes.add(donante);
      await File(_filePath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(donantes),
      );

      return {'exito': true, 'mensaje': 'Donante registrado correctamente.'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al guardar el donante: $e'};
    }
  }

  /// Método de compatibilidad para la UI (RegistroDonanteScreen) que retorna booleano,
  /// integrando la validación estricta de RUT duplicado y elegibilidad.
  static Future<bool> guardarDonanteReal(
      Map<String, dynamic> donanteData) async {
    final resultado = await guardarDonante(donanteData);
    return resultado['exito'] == true;
  }
}