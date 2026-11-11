import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El formulario es válido.')),
      );
    }
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
              decoration: const InputDecoration(
                labelText: 'Dato de ejemplo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Completa este campo';
                }
                return null;
              },
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
                  setState((){
                    _fechaSeleccionada = fecha;
                    _fechaController.text = 
                      '${fecha.day.toString().padLeft(2, '0')}/'
                      '${fecha.month.toString().padLeft(2, '0')}/'
                      '${fecha.year}';
                  });
                }
              },
              validator: (_) => _fechaSeleccionada == null ? 'Selecciona una fecha' : null, 
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
                      data: MediaQuery.of(context).copyWith(
                        alwaysUse24HourFormat: true,
                      ),
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
