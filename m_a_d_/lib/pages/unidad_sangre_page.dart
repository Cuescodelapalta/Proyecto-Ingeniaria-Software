import 'package:flutter/material.dart';
import 'package:m_a_d_/repositories/unidad_sangre_repository.dart';

class UnidadSangrePage extends StatelessWidget {
  const UnidadSangrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esqueleto Inventario de Sangre')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await UnidadSangreRepository.guardarUnidadSangreEsqueleto();
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unidad de sangre guardada correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al guardar la unidad de sangre: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Guardar unidad de prueba'),
        ),
      ),
    );
  }
}