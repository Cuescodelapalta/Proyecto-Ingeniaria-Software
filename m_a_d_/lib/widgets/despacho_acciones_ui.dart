import 'package:flutter/material.dart';

Future<String?> mostrarModalEditarDestino(
  BuildContext context, {
  required String destinoActual,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ModalEditarDestinoDialog(destinoActual: destinoActual),
  );
}

class _ModalEditarDestinoDialog extends StatefulWidget {
  final String destinoActual;

  const _ModalEditarDestinoDialog({required this.destinoActual});

  @override
  State<_ModalEditarDestinoDialog> createState() =>
      _ModalEditarDestinoDialogState();
}

class _ModalEditarDestinoDialogState extends State<_ModalEditarDestinoDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.destinoActual);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar hospital de destino'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Hospital / Centro médico de destino',
            border: OutlineInputBorder(),
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'El destino es obligatorio';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class TarjetaDespachoInteractiva extends StatefulWidget {
  final Map<String, dynamic> ordenInicial;
  final Future<bool> Function(dynamic id, String nuevoDestino)? onGuardarDestino;

  const TarjetaDespachoInteractiva({
    super.key,
    required this.ordenInicial,
    this.onGuardarDestino,
  });

  @override
  State<TarjetaDespachoInteractiva> createState() =>
      _TarjetaDespachoInteractivaState();
}

class _TarjetaDespachoInteractivaState
    extends State<TarjetaDespachoInteractiva> {
  late Map<String, dynamic> _orden;

  @override
  void initState() {
    super.initState();
    _orden = Map<String, dynamic>.from(widget.ordenInicial);
  }

  Future<void> _manejarEdicion() async {
    final nuevoDestino = await mostrarModalEditarDestino(
      context,
      destinoActual: (_orden['hospital_destino'] ?? '').toString(),
    );
    if (nuevoDestino == null) return;

    final ok = widget.onGuardarDestino != null
        ? await widget.onGuardarDestino!(_orden['id'], nuevoDestino)
        : true;

    if (ok && mounted) {
      setState(() {
        _orden['hospital_destino'] = nuevoDestino;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Destino del despacho actualizado correctamente.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String estado = (_orden['estado'] ?? 'Pendiente').toString();
    final bool esPendiente = estado == 'Pendiente';
    final String ruta =
        '${_orden['sede_origen']} → ${_orden['hospital_destino']}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ruta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(estado)),
              ],
            ),
            if (esPendiente) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _manejarEdicion,
                icon: const Icon(Icons.edit),
                label: const Text('Editar destino'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}