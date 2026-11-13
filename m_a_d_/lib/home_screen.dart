import 'package:flutter/material.dart';
import 'package:m_a_d_/registro_unidades_screen.dart';
import 'package:m_a_d_/inventario_unidades_screen.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key}); 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CBS - Banco de Sangre'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón para ir al formulario de registro
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistroUnidadesScreen()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar nueva unidad'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Botón para ir a la pantalla de inventario de unidades
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventarioUnidadesScreen()),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Revisar inventario'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}