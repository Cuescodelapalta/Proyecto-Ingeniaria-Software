import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

void main() {
  const String filePath = 'donantes.json';

  Map<String, dynamic> donante(String rut) => {
        'rut': rut,
        'nombre': 'Donante Test',
        'fechaNacimiento': '2000-01-01',
        'peso': 70.0,
        'tipoSangre': 'O+',
        'telefono': 912345678,
        'elegibilidad': 'Apto',
        'fechaRetorno': null,
      };

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

  test('Rechaza un donante cuyo RUT ya está en el .json', () async {
    await File(filePath).writeAsString(jsonEncode([donante('123456785')]));
    final resultado = await DonanteRepository.guardarDonante(donante('123456785'));
    expect(resultado['exito'], isFalse);
    expect(resultado['mensaje'], contains('RUT duplicado'));
    final lista = jsonDecode(await File(filePath).readAsString()) as List<dynamic>;
    expect(lista.length, 1);
  });
  test('Rechaza RUT duplicado aunque venga con puntos y guion', () async {
    await File(filePath).writeAsString(jsonEncode([donante('123456785')]));
    final resultado = await DonanteRepository.guardarDonante(donante('12.345.678-5'));
    expect(resultado['exito'], isFalse);
    expect(resultado['mensaje'], contains('RUT duplicado'));
  });
  test('Se guarda con exito un donante nuevo (el archivo no existía)', () async {
    expect(await File(filePath).exists(), isFalse);
    final resultado = await DonanteRepository.guardarDonante(donante('123456785'));
    expect(resultado['exito'], isTrue);
    final lista = jsonDecode(await File(filePath).readAsString()) as List<dynamic>;
    expect(lista.length, 1);
    expect(lista.first['rut'], '123456785');
  });
  test('Se rechaza el segundo registro del donante porque su RUT ya esta registrado', () async {
    final primero = await DonanteRepository.guardarDonante(donante('123456785'));
    final segundo = await DonanteRepository.guardarDonante(donante('123456785'));
    expect(primero['exito'], isTrue);
    expect(segundo['exito'], isFalse);
    expect(segundo['mensaje'], contains('RUT duplicado'));
    final lista = jsonDecode(await File(filePath).readAsString()) as List<dynamic>;
    expect(lista.length, 1);
  });
  test('se aceptan nuevos donantes con RUTs distintos', () async {
    await File(filePath).writeAsString(jsonEncode([donante('123456785')]));
    final resultado = await DonanteRepository.guardarDonante(donante('98765432K'));
    expect(resultado['exito'], isTrue);
    final lista = jsonDecode(await File(filePath).readAsString()) as List<dynamic>;
    expect(lista.length, 2);
  });
}