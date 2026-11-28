import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

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

/// Busca un donante por su [rut] en `DonanteRepository` y abre el modal de
/// edición precargado con sus datos actuales.
///
/// Muestra un mensaje de error si el RUT no existe en `donantes.json` y
/// retorna `true` si la actualización fue exitosa.
Future<bool?> mostrarModalEditarDonantePorRut(
  BuildContext context,
  String rut,
) async {
  final donante = await DonanteRepository.buscarDonantePorRut(rut);
  if (!context.mounted) return null;

  if (donante == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se encontró ningún donante con el RUT $rut.')),
    );
    return false;
  }

  return mostrarModalEditarDonante(context, donante);
}

/// Diálogo modal para modificar los datos editables y la elegibilidad
/// de un donante existente (US03 - Task 3.3).
///
/// Mantiene `rut` y `tipoSangre` como campos de solo lectura y exige una
/// `fechaRetorno` futura cuando la elegibilidad es `'Diferido temporalmente'`
/// (regla de negocio RF-11).
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

  late String _elegibilidad;
  DateTime? _fechaRetorno;
  String? _errorMensaje;
  bool _guardando = false;

  static const List<String> _opcionesElegibilidad = [
    'Apto',
    'Diferido temporalmente',
    'Rechazado',
  ];

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

    final elegibilidadInicial = (widget.donante['elegibilidad'] ?? 'Apto')
        .toString();
    _elegibilidad = _opcionesElegibilidad.contains(elegibilidadInicial)
        ? elegibilidadInicial
        : (elegibilidadInicial == 'Diferido'
              ? 'Diferido temporalmente'
              : 'Apto');

    final rawFecha = widget.donante['fechaRetorno'];
    if (rawFecha is String && rawFecha.trim().isNotEmpty) {
      _fechaRetorno = DateTime.tryParse(rawFecha.trim());
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  bool get _requiereFechaRetorno => _elegibilidad == 'Diferido temporalmente';

  String _formatearFecha(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  /// Abre el selector nativo de fechas permitiendo probar la validación de
  /// dominio (RF-11) en `DonanteRepository.actualizarDonante`.
  Future<void> _seleccionarFechaRetorno() async {
    final ahora = DateTime.now();
    final manana = DateTime(ahora.year, ahora.month, ahora.day + 1);
    final fechaInicial =
        (_fechaRetorno != null && _fechaRetorno!.isAfter(manana))
        ? _fechaRetorno!
        : manana;

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(ahora.year + 5),
    );

    if (seleccionada != null) {
      setState(() {
        _fechaRetorno = seleccionada;
        _errorMensaje = null;
      });
    }
  }

  /// Valida el formulario y persiste la actualización en `DonanteRepository`.
  Future<void> _guardarCambios() async {
    setState(() => _errorMensaje = null);

    if (!_formKey.currentState!.validate()) return;

    if (_requiereFechaRetorno && _fechaRetorno == null) {
      setState(() {
        _errorMensaje = 'Debe seleccionar una fecha de habilitación futura para un donante diferido temporalmente.';
      });
      return;
    }

    setState(() => _guardando = true);

    try {
      final rut = widget.donante['rut'].toString();
      final resultado = await DonanteRepository.actualizarDonante(rut, {
        'nombre': _nombreController.text.trim(),
        'telefono': int.parse(_telefonoController.text.trim()),
        'peso': double.parse(_pesoController.text.trim().replaceAll(',', '.')),
        'elegibilidad': _elegibilidad,
        'fechaRetorno': _requiereFechaRetorno
            ? _fechaRetorno!.toIso8601String()
            : null,
      });

      if (!mounted) return;

      if (resultado['exito'] == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMensaje =
              (resultado['mensaje'] ?? 'No se pudo actualizar el donante.')
                  .toString();
          _guardando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMensaje = 'Error al actualizar: $e';
        _guardando = false;
      });
    }
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
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: const Key('dropdown_editar_elegibilidad'),
                  initialValue: _elegibilidad,
                  decoration: const InputDecoration(
                    labelText: 'Elegibilidad',
                    border: OutlineInputBorder(),
                  ),
                  items: _opcionesElegibilidad
                      .map(
                        (estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ),
                      )
                      .toList(),
                  onChanged: (nuevoEstado) {
                    if (nuevoEstado == null) return;
                    setState(() {
                      _elegibilidad = nuevoEstado;
                      _errorMensaje = null;
                      if (!_requiereFechaRetorno) {
                        _fechaRetorno = null;
                      }
                    });
                  },
                ),
                if (_requiereFechaRetorno) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('boton_fecha_retorno'),
                    onPressed: _seleccionarFechaRetorno,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _fechaRetorno == null
                          ? 'Seleccionar fecha de habilitación *'
                          : 'Fecha de habilitación: ${_formatearFecha(_fechaRetorno!)}',
                    ),
                  ),
                ],
                if (_errorMensaje != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMensaje!,
                    key: const Key('mensaje_error_edicion'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('boton_cancelar_edicion'),
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('boton_guardar_edicion'),
          onPressed: _guardando ? null : _guardarCambios,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
