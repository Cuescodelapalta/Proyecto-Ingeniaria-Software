import 'package:flutter/material.dart';

class RegistroUnidadesScreen extends StatefulWidget {
  const RegistroUnidadesScreen({super.key});

  @override
  State<RegistroUnidadesScreen> createState() => _RegistroUnidadesScreenState();
}

class _RegistroUnidadesScreenState extends State<RegistroUnidadesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _datoController = TextEditingController();

  @override
  void dispose() {
    _datoController.dispose();
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
