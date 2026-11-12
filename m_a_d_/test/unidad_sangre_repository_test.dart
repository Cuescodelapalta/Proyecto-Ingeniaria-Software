import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/unidad_sangre_repository.dart';

void main() {
  const String filePath = 'inventario_sangre.json';

  setUp(() async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  tearDown(() async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  test('Task07: Guardar registro base con éxito',() async {
      //verifica que el archivo no existe antes de la prueba
      final file = File(filePath);
      expect(await file.exists(), false);

      //verifica que el archivo fue creado
      await UnidadSangreRepository.guardarUnidadSangreEsqueleto();
      expect(await file.exists(), true);
      
      //verifica que solo exista un registro en el archivo
      final String contenido = await file.readAsString();
      final List<dynamic> inventario = jsonDecode(contenido);
      expect(inventario.length, 1);

      //verifica que el registro tenga los valores esperados
      final registro = inventario.last;
      expect(registro['rut'], '1-9');
      expect(registro['volumenMl'], 450);
      expect(registro['sede'], 'Concepción');
      expect(registro['estado'], 'Disponible');
    },
  );
}