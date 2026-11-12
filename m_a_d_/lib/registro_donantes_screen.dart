import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistroDonanteScreen extends StatefulWidget {
  const RegistroDonanteScreen({super.key});

  @override
  State<RegistroDonanteScreen> createState() => _RegistroDonanteScreenState();
}

class _RegistroDonanteScreenState extends State<RegistroDonanteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _controladorRut = TextEditingController();
  final _controladorNombre = TextEditingController();
  final _controladorFechaNacimiento = TextEditingController();
  final _controladorPeso = TextEditingController();
  final _controladorTelefono = TextEditingController();

  String? _tipoSangreSeleccionado;

  final List<String> _tiposSangre = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void dispose() {
    _controladorRut.dispose();
    _controladorNombre.dispose();
    _controladorFechaNacimiento.dispose();
    _controladorPeso.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar nuevo donante'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _construirCampoTexto(
                controlador: _controladorRut,
                etiqueta: 'RUT',
                validador: (value) => (value == null || value.trim().isEmpty)
                    ? 'El RUT es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorNombre,
                etiqueta: 'Nombre completo',
                validador: (value) => (value == null || value.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorFechaNacimiento,
                etiqueta: 'Fecha de nacimiento',
                tipoTeclado: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorPeso,
                etiqueta: 'Peso',
                tipoTeclado: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre',
                  border: OutlineInputBorder(),
                ),
                initialValue: _tipoSangreSeleccionado,
                items: _tiposSangre
                    .map(
                      (tipo) => DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => _tipoSangreSeleccionado = newValue),
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorTelefono,
                etiqueta: 'Teléfono',
                tipoTeclado: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Información guardada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String etiqueta,
    TextInputType tipoTeclado = TextInputType.text,
    FormFieldValidator<String>? validador,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipoTeclado,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
      validator: validador,
    );
  }
}
