import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

void main() {
  const String filePath = 'donantes.json';

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

  test('Task02 (T01): Crear archivo JSON y guardar registro esqueleto con RUT 1-9', () async {
    final file = File(filePath);
    expect(await file.exists(), isFalse);

    bool resultado = await DonanteRepository.guardarDonanteEsqueleto();

    expect(resultado, isTrue);
    expect(await file.exists(), isTrue);

    final String contenido = await file.readAsString();
    final List<dynamic> datos = jsonDecode(contenido);

    expect(datos, isNotEmpty);
    expect(datos.last['rut'], equals('1-9'));
  });
}