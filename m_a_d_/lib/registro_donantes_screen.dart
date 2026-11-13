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
                  // Restringe la entrada a solo 11 digitos númericos
                  LengthLimitingTextInputFormatter(11),
                ],
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
                      'elegibilidad': 'Pendiente', //Reemplazar esto para task 4
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
                      setState(() => _tipoSangreSeleccionado = null);
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
  /// [tipoTeclado] adapta el teclado del dispositivo.
  /// [validador] recibe una función para evaluar que no existan campos vacíos.
  /// [inputFormatters] permite restringir los caracteres que se pueden ingresar.
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
