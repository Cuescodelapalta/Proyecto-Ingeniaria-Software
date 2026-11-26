import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Muestra el modal de edición para un [donante] existente y retorna `true`
/// si se guardaron cambios correctamente en `DonanteRepository`.
Future<bool?> mostrarModalEditarDonante(
  BuildContext context,
  Map<String, dynamic> donante,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EditarDonanteModal(donante: donante),
  );
}

/// Diálogo modal para modificar los datos editables y la elegibilidad
/// de un donante existente (US03 - Task 3.3).
///
/// Mantiene `rut` y `tipoSangre` como campos de solo lectura.
class EditarDonanteModal extends StatefulWidget {
  /// Crea el modal precargado con los datos actuales del [donante].
  const EditarDonanteModal({super.key, required this.donante});

  /// Mapa con los datos del donante obtenidos desde `DonanteRepository`.
  final Map<String, dynamic> donante;

  @override
  State<EditarDonanteModal> createState() => _EditarDonanteModalState();
}

class _EditarDonanteModalState extends State<EditarDonanteModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _pesoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: (widget.donante['nombre'] ?? '').toString(),
    );
    _telefonoController = TextEditingController(
      text: (widget.donante['telefono'] ?? '').toString(),
    );
    _pesoController = TextEditingController(
      text: (widget.donante['peso'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rut = (widget.donante['rut'] ?? '').toString();
    final tipoSangre = (widget.donante['tipoSangre'] ?? '').toString();

    return AlertDialog(
      title: const Text('Editar Donante'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: rut,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'RUT (No editable)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        initialValue: tipoSangre,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Grupo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('campo_editar_nombre'),
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('campo_editar_telefono'),
                        controller: _telefonoController,
                        keyboardType: TextInputType.number,
                        maxLength: 9,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          hintText: '912345678',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          final limpio = valor?.trim() ?? '';
                          if (!RegExp(r'^\d{9}$').hasMatch(limpio)) {
                            return 'Debe tener 9 dígitos';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('campo_editar_peso'),
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          final limpio = (valor ?? '').trim().replaceAll(
                            ',',
                            '.',
                          );
                          final peso = double.tryParse(limpio);
                          if (peso == null || peso <= 0) {
                            return 'Peso inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('boton_cancelar_edicion'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('boton_guardar_edicion'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
