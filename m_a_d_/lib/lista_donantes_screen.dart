import 'package:flutter/material.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';

class ListaDonantesScreen extends StatefulWidget {
  const ListaDonantesScreen({super.key});

  @override
  State<ListaDonantesScreen> createState() => _ListaDonantesScreenState();
}

class _ListaDonantesScreenState extends State<ListaDonantesScreen> {
  late Future<List<Map<String, dynamic>>> _donantesFuture;

  @override
  void initState() {
    super.initState();
    _cargarDonantes();
  }

  void _cargarDonantes() {
    _donantesFuture = DonanteRepository.listarDonantes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de donantes'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _donantesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar la lista de donantes.'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(_cargarDonantes);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final donantes = snapshot.data ?? [];
          if (donantes.isEmpty) {
            return const Center(
              child: Text('Aún no hay donantes registrados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: donantes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final donante = donantes[index];
              final nombre = (donante['nombre'] ?? '').toString().trim();
              final rut = (donante['rut'] ?? '').toString().trim();

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(nombre.isEmpty ? 'Sin nombre' : nombre),
                  subtitle: Text('RUT: ${rut.isEmpty ? 'Sin RUT' : rut}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
