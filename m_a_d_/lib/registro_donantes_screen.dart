import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

/// Pantalla para el registro de información de donantes
/// Captura los datos ingresados mediante un formulario interactivo.
class RegistroDonanteScreen extends StatefulWidget {
  const RegistroDonanteScreen({super.key});

  @override
  State<RegistroDonanteScreen> createState() => _RegistroDonanteScreenState();
}

class _RegistroDonanteScreenState extends State<RegistroDonanteScreen> {
  // Llave global que identifica el formulario y permite ejecutar las validaciones
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar y leer el texto ingresado en cada campo.
  final _controladorRut = TextEditingController();
  final _controladorNombre = TextEditingController();
  final _controladorFechaNacimiento = TextEditingController();
  final _controladorPeso = TextEditingController();
  final _controladorTelefono = TextEditingController();

  /// Almacena el valor actual en el menú desplegable.
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

  String? _elegibilidadSeleccionada;

  final List<String> _estadosElegibilidad = [
    'Apto',
    'Diferido',
    'Rechazado',
  ];
  
  /// Libera los recursos de memoria al cerrar la ventana, para evitar fugas de memoria.
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9K]')),
                ],
                validador: (value) {
                  if (value == null || value.trim().isEmpty) {  
                    return 'El RUT es obligatorio';
                  }
                  if (!RegExp(r'^\d{1,8}[0-9K]$').hasMatch(value.trim())) {
                    return 'Ingresa el RUT sin puntos ni guion';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorNombre,
                etiqueta: 'Nombre completo',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
                validador: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorFechaNacimiento,
                etiqueta: 'Fecha de nacimiento',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                ],
                validador: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La fecha de nacimiento es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorPeso,
                etiqueta: 'Peso (kg)',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validador: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El peso es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Debe seleccionar un tipo de sangre' : null,
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Estado de evaluación clínica',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Debe seleccionar un estado de evaluación clínica' : null,
                initialValue: _elegibilidadSeleccionada,
                items: _estadosElegibilidad
                    .map(
                      (estado) => DropdownMenuItem<String>(
                        value: estado,
                        child: Text(estado),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _elegibilidadSeleccionada = value),
              ),
              const SizedBox(height: 16),
              _construirCampoTexto(
                controlador: _controladorTelefono,
                etiqueta: 'Teléfono',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  // Restringe la entrada a solo 11 digitos númericos
                  LengthLimitingTextInputFormatter(11),
                ],
                validador: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final nuevoDonante = {
                      'rut': _controladorRut.text.trim(),
                      'nombre': _controladorNombre.text.trim(),
                      'fechaNacimiento': _controladorFechaNacimiento.text
                          .trim(),
                      'peso':
                          double.tryParse(_controladorPeso.text.trim()) ?? 0.0,
                      'tipoSangre': _tipoSangreSeleccionado,
                      'telefono':
                          int.tryParse(_controladorTelefono.text.trim()) ?? 0,
                      'elegibilidad': _elegibilidadSeleccionada, 
                      'fechaRetorno': null,
                    };
                    bool exito = await DonanteRepository.guardarDonanteReal(
                      nuevoDonante,
                    );
                    if (exito && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Información del donante guardada exitosamente',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _formKey.currentState!.reset();
                      _controladorRut.clear();
                      _controladorNombre.clear();
                      _controladorFechaNacimiento.clear();
                      _controladorPeso.clear();
                      _controladorTelefono.clear();
                      setState(() {
                        _tipoSangreSeleccionado = null;
                        _elegibilidadSeleccionada = null;
                      },);
                    }
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

  /// Construye una celda de texto reutilizable para las distintas opciones.
  /// [controlador] administra el texto ingresado.
  /// [etiqueta] define el texto flotante de ayuda visual.
  /// [validador] recibe una función para evaluar que no existan campos vacíos.
  /// [inputFormatters] permite restringir los caracteres que se pueden ingresar.
  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String etiqueta,
    FormFieldValidator<String>? validador,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controlador,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
      validator: validador,
    );
  }
}
