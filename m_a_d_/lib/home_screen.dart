import 'package:flutter/material.dart';
import 'package:m_a_d_/registro_unidades_screen.dart';
import 'package:m_a_d_/registro_donantes_screen.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key}); 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
          ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistroDonanteScreen()),
            );
          }, 
          child: const Text('Registro donantes')),
          const SizedBox(height: 16,),
          ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistroUnidadesScreen()),
            );
          }, 
          child: const Text('Registro unidades')),
        ],)
      )
    );
  }
}