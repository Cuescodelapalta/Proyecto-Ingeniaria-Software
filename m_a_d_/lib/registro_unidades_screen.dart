import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

class RegistroUnidadesScreen extends StatefulWidget {
  const RegistroUnidadesScreen({super.key});

  @override
  State<RegistroUnidadesScreen> createState() => _RegistroUnidadesScreenState();
}

class _RegistroUnidadesScreenState extends State<RegistroUnidadesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _datoController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  @override
  void dispose() {
    _datoController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  void _validarFormulario() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El formulario es válido.')));
    }
  }

  String? _validarRut(String? value) {
    if (value == null || value.isEmpty) {
      return 'Completa este campo';
    }

    final rut = value.toUpperCase();
    final formatoValido = RegExp(r'^\d{1,8}[0-9K]$').hasMatch(rut);
    if (!formatoValido) {
      return 'Ingresa el RUT sin puntos ni guion (ej. 123456785)';
    }

    final cuerpo = rut.substring(0, rut.length - 1);
    if (cuerpo.startsWith('0')) {
      return 'Ingresa un RUT válido (ej. 123456785)';
    }

    var suma = 0;
    var multiplicador = 2;
    for (var i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }

    final resto = 11 - (suma % 11);
    final digitoVerificador = switch (resto) {
      11 => '0',
      10 => 'K',
      _ => resto.toString(),
    };

    if (rut[rut.length - 1] != digitoVerificador) {
      return 'El dígito verificador del RUT no es válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de unidades')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _datoController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              maxLength: 9,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
              ],
              decoration: const InputDecoration(
                labelText: 'RUT',
                border: OutlineInputBorder(),
              ),
              validator: _validarRut,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _fechaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha de extracción',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada ?? DateTime.now(),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2100),
                );

                if (fecha != null) {
                  setState(() {
                    _fechaSeleccionada = fecha;
                    _fechaController.text =
                        '${fecha.day.toString().padLeft(2, '0')}/'
                        '${fecha.month.toString().padLeft(2, '0')}/'
                        '${fecha.year}';
                  });
                }
              },
              validator: (_) =>
                  _fechaSeleccionada == null ? 'Selecciona una fecha' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _horaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Hora de extracción',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                final hora = await showTimePicker(
                  context: context,
                  initialTime: _horaSeleccionada ?? TimeOfDay.now(),
                  initialEntryMode: TimePickerEntryMode.inputOnly,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );

                if (hora != null) {
                  setState(() {
                    _horaSeleccionada = hora;
                    _horaController.text =
                        '${hora.hour.toString().padLeft(2, '0')}:'
                        '${hora.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
              validator: (_) =>
                  _horaSeleccionada == null ? 'Selecciona una hora' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _validarFormulario,
              child: const Text('Validar formulario'),
            ),
          ],
        ),
      ),
    );
  }
}
