import 'package:flutter/material.dart';
import '../repositories/donante_repository.dart';

class EsqueletoPage extends StatelessWidget {
  const EsqueletoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba Task02 - Esqueleto')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            bool exito = await DonanteRepository.guardarDonanteEsqueleto();

            if (exito && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Éxito! Registro fijo (RUT 1-9) guardado correctamente en el JSON.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: const Text('Probar Guardado Esqueleto (RUT 1-9)'),
        ),
      ),
    );
  }
}