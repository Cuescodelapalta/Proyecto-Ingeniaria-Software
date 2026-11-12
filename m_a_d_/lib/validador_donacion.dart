import 'dart:convert';
import 'dart:io';
import 'package:m_a_d_/repositories/unidad_repository.dart';

class ValidadorDonacion {
  static const String _pathDonantes = 'donantes.json';

  /// Valida que el donante exista, sea 'Apto', hereda su tipo de sangre
  /// y registra la unidad usando la lógica de la Task08 (UnidadRepository).
  static Future<Map<String, Object>> procesarYGuardarUnidad({
    required String rutDonante,
    required DateTime fechaExtraccion,
    required int volumen,
  }) async {
    try {
      final fileDonantes = File(_pathDonantes);
      if (!await fileDonantes.exists()) {
        return {
          'exito': false,
          'mensaje': 'No se encontró el archivo de donantes (donantes.json).'
        };
      }

      final List<dynamic> donantes = jsonDecode(await fileDonantes.readAsString());

      // 1. Buscar al donante por su RUT de forma segura
      dynamic donanteEncontrado;
      for (var d in donantes) {
        if (d['rut'] == rutDonante) {
          donanteEncontrado = d;
          break;
        }
      }

      if (donanteEncontrado == null) {
        return {
          'exito': false,
          'mensaje': 'El RUT ingresado no está registrado en el sistema.'
        };
      }

      // 2. Validar elegibilidad clínica
      final String elegibilidad = donanteEncontrado['elegibilidad'] ?? 'No especificado';
      if (elegibilidad.toLowerCase() != 'apto') {
        return {
          'exito': false,
          'mensaje': 'El donante no cumple con la elegibilidad (Estado actual: $elegibilidad).'
        };
      }

      // 3. Heredar el tipo de sangre del donante (respeta 'tipoSangre' o 'tipo_sangre')
      final String tipoSangreHeredado = donanteEncontrado['tipoSangre'] ?? donanteEncontrado['tipo_sangre'] ?? 'O+';

      // 4. Guardar la unidad usando el UnidadRepository (Task08)
      final bool guardadoExitoso = await UnidadRepository.guardarUnidad(
        tipoSangre: tipoSangreHeredado,
        fechaExtraccion: fechaExtraccion,
        volumen: volumen,
      );

      if (!guardadoExitoso) {
        return {
          'exito': false,
          'mensaje': 'Error al intentar guardar la unidad en unidades.json.'
        };
      }

      return {
        'exito': true,
        'mensaje': 'Unidad procesada con éxito. Tipo de sangre heredado: $tipoSangreHeredado'
      };

    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error inesperado durante la validación: $e'
      };
    }
  }
}