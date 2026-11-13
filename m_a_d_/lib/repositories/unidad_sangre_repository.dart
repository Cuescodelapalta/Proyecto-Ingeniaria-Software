import 'dart:convert';
import 'dart:io';

class UnidadSangreRepository {
  static const String _filePath = 'inventario_sangre.json';

  static Future<void> guardarUnidadSangreEsqueleto() async {
    final file = File(_filePath);

    // si el archivo no existe se crea con una lista vacia
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode([]));
    }

    final String contenido = await file.readAsString();
    final dynamic datos = jsonDecode(contenido);

    // Comprobar que el JSON tenga la estructura esperada.
    if (datos is! List) {
      throw const FormatException(
        'El archivo de inventario no contiene una lista válida.',
      );
    }

    List<dynamic> listaUnidades = datos;
    final registroFijo = {
      'rut': '1-9',
      'volumenMl': 450,
      'sede': 'Concepción',
      'estado': 'Disponible',
    };

    listaUnidades.add(registroFijo);

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(listaUnidades),
    );
  }
}