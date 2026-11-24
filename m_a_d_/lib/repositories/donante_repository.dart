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
    return donantes.any(
      (d) =>
          d is Map &&
          d['rut'] is String &&
          normalizarRut(d['rut'] as String) == buscado,
    );
  }

  /// true si el RUT ya está registrado en donantes.json.
  static Future<bool> existeRut(String rut) async {
    return _contieneRut(await _leerDonantes(), rut);
  }

  /// Guarda un donante solo si su RUT no existe ya en donantes.json
  static Future<Map<String, Object>> guardarDonante(
    Map<String, dynamic> donante,
  ) async {
    try {
      final rut = donante['rut'];
      if (rut is! String || rut.trim().isEmpty) {
        return {'exito': false, 'mensaje': 'El donante debe tener un RUT.'};
      }

      const estadosEvaluacion = {
        'Apto',
        'Diferido',
        'Diferido temporalmente',
        'Rechazado',
      };
      final elegibilidad = donante['elegibilidad'];
      if (elegibilidad is! String ||
          !estadosEvaluacion.contains(elegibilidad)) {
        return {
          'exito': false,
          'mensaje': 'La elegibilidad debe ser Apto, Diferido o Rechazado.',
        };
      }

      // Validación RF-11: Si es diferido temporalmente, debe registrar cuándo podrá volver a donar
      if (elegibilidad == 'Diferido' ||
          elegibilidad == 'Diferido temporalmente') {
        final fechaRetorno = donante['fechaRetorno'];
        if (fechaRetorno == null ||
            (fechaRetorno is String && fechaRetorno.trim().isEmpty)) {
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
      await File(_filePath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(donantes));

      return {'exito': true, 'mensaje': 'Donante registrado correctamente.'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al guardar el donante: $e'};
    }
  }

  /// Método de compatibilidad para la UI (RegistroDonanteScreen) que retorna booleano,
  /// integrando la validación estricta de RUT duplicado y elegibilidad.
  static Future<bool> guardarDonanteReal(
    Map<String, dynamic> donanteData,
  ) async {
    final resultado = await guardarDonante(donanteData);
    return resultado['exito'] == true;
  }

  /// Retorna todos los donantes registrados en `donantes.json` como lista de mapas.
  ///
  /// va a ser usado por la vista de listado/búsqueda y para precargar datos al editar.
  static Future<List<Map<String, dynamic>>> obtenerDonantes() async {
    final datos = await _leerDonantes();
    return datos.whereType<Map<String, dynamic>>().toList();
  }

  /// Busca y retorna una copia de los datos de un donante por su [rut].
  ///
  /// Retorna `null` si el [rut] está vacío o no existe en `donantes.json`.
  static Future<Map<String, dynamic>?> buscarDonantePorRut(String rut) async {
    if (rut.trim().isEmpty) return null;
    final buscado = normalizarRut(rut);
    final donantes = await _leerDonantes();

    for (final d in donantes) {
      if (d is Map<String, dynamic> &&
          d['rut'] is String &&
          normalizarRut(d['rut'] as String) == buscado) {
        return Map<String, dynamic>.from(d);
      }
    }
    return null;
  }

  /// Busca y retorna los donantes cuyo nombre contenga [nombre]
  /// (insensible a mayúsculas y espacios laterales).
  ///
  /// Si [nombre] está vacío, retorna una lista vacía.
  static Future<List<Map<String, dynamic>>> buscarDonantePorNombre(
    String nombre,
  ) async {
    final texto = nombre.trim().toLowerCase();
    if (texto.isEmpty) return [];

    final todos = await obtenerDonantes();
    return todos.where((d) {
      final nombreDonante = (d['nombre'] ?? '').toString().toLowerCase();
      return nombreDonante.contains(texto);
    }).toList();
  }

  /// Actualiza los datos editables de un donante existente identificado por [rut].
  ///
  /// No cambia el `'rut'` y el `'tipoSangre'` originales.
  /// Si `'elegibilidad'` cambia a `'Diferido temporalmente'` (o `'Diferido'`),
  /// exige una fecha de habilitación estrictamente posterior a hoy.
  ///
  /// Lanza [StateError] si no existe ningún donante con el [rut] indicado.
  /// Retorna un mapa con `'exito'` (`bool`) y `'mensaje'` (`String`).
  static Future<Map<String, Object>> actualizarDonante(
    String rut,
    Map<String, dynamic> datosActualizados,
  ) async {
    final donantes = await _leerDonantes();
    final buscado = normalizarRut(rut);
    final indice = donantes.indexWhere(
      (d) =>
          d is Map &&
          d['rut'] is String &&
          normalizarRut(d['rut'] as String) == buscado,
    );

    if (indice == -1) {
      throw StateError(
        'No se encontró ningún donante registrado con el RUT $rut.',
      );
    }

    const estadosValidos = {
      'Apto',
      'Diferido',
      'Diferido temporalmente',
      'Rechazado',
    };
    final elegibilidad = datosActualizados['elegibilidad'];
    if (elegibilidad is! String || !estadosValidos.contains(elegibilidad)) {
      return {'exito': false, 'mensaje': 'Estado de elegibilidad no válido.'};
    }

    final esDiferido =
        elegibilidad == 'Diferido temporalmente' || elegibilidad == 'Diferido';

    String? fechaHabilitacionFormateada;
    if (esDiferido) {
      final rawFecha =
          datosActualizados['fechaHabilitacion'] ??
          datosActualizados['fechaRetorno'];

      if (rawFecha == null || (rawFecha is String && rawFecha.trim().isEmpty)) {
        return {
          'exito': false,
          'mensaje': 'La fecha de habilitación es obligatoria para un donante diferido temporalmente.',
        };
      }

      final parsedFecha = rawFecha is DateTime
          ? rawFecha
          : DateTime.tryParse(rawFecha.toString().trim());
      if (parsedFecha == null) {
        return {
          'exito': false,
          'mensaje': 'El formato de la fecha de habilitación no es válido.',
        };
      }

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final fechaSoloDia = DateTime(
        parsedFecha.year,
        parsedFecha.month,
        parsedFecha.day,
      );

      if (!fechaSoloDia.isAfter(hoy)) {
        return {
          'exito': false,
          'mensaje': 'La fecha de habilitación debe ser futura.',
        };
      }

      fechaHabilitacionFormateada =
          '${fechaSoloDia.year}-${fechaSoloDia.month.toString().padLeft(2, '0')}-${fechaSoloDia.day.toString().padLeft(2, '0')}';
    }

    final donanteActual = Map<String, dynamic>.from(donantes[indice] as Map);

    final donanteEditado = <String, dynamic>{
      ...donanteActual,
      if (datosActualizados['nombre'] != null)
        'nombre': datosActualizados['nombre'].toString().trim(),
      if (datosActualizados['fechaNacimiento'] != null)
        'fechaNacimiento': datosActualizados['fechaNacimiento']
            .toString()
            .trim(),
      if (datosActualizados['peso'] != null) 'peso': datosActualizados['peso'],
      if (datosActualizados['telefono'] != null)
        'telefono': datosActualizados['telefono'],
      'elegibilidad': elegibilidad,
      'fechaRetorno': fechaHabilitacionFormateada,
      'fechaHabilitacion': fechaHabilitacionFormateada,
    };

    donantes[indice] = donanteEditado;

    await File(_filePath)
        .writeAsString(const JsonEncoder.withIndent('  ').convert(donantes));

    return {'exito': true, 'mensaje': 'Donante actualizado correctamente.'};
  }
}
