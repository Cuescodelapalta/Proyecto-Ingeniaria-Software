
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

  static Future<bool> guardarDonanteReal(Map<String,dynamic> donanteData)async{
    try {
      final file = File(_filePath);

      if (!await file.exists()) {
        await file.writeAsString(jsonEncode([]));
      }

      final String contenido = await file.readAsString();
      List<dynamic> listaDonantes = jsonDecode(contenido);

      listaDonantes.add(donanteData);

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(listaDonantes),
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}