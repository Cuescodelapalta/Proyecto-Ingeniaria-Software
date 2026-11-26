import 'package:flutter/material.dart';
import 'package:m_a_d_/repositories/donante_repository.dart';
import 'package:m_a_d_/registro_donantes_screen.dart';

class ListaDonantesScreen extends StatefulWidget {
  const ListaDonantesScreen({super.key});

  @override
  State<ListaDonantesScreen> createState() => _ListaDonantesScreenState();
}

class _ListaDonantesScreenState extends State<ListaDonantesScreen> {
  late Future<List<Map<String, dynamic>>> _donantesFuture;
  String _filtroRut = '';

  @override
  void initState() {
    super.initState();
    _cargarDonantes();
  }

  void _cargarDonantes() {
    _donantesFuture = DonanteRepository.listarDonantes();
  }

  void _mostrarDetalleDonante(
    BuildContext context,
    Map<String, dynamic> donante,
  ) {
    final nombre = (donante['nombre'] ?? '').toString().trim();
    final detalles = <MapEntry<String, String>>[
      MapEntry('RUT', _valorDetalle(donante['rut'])),
      MapEntry(
        'Fecha de nacimiento',
        _valorDetalle(donante['fechaNacimiento']),
      ),
      MapEntry('Peso', '${_valorDetalle(donante['peso'])} kg'),
      MapEntry(
        'Tipo de sangre',
        _valorDetalle(donante['tipoSangre'] ?? donante['tipo_sangre']),
      ),
      MapEntry('Teléfono', _valorDetalle(donante['telefono'])),
      MapEntry('Elegibilidad', _valorDetalle(donante['elegibilidad'])),
      MapEntry(
        'Fecha de retorno',
        _valorDetalle(donante['fechaRetorno'], valorVacio: 'No aplica'),
      ),
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nombre.isEmpty ? 'Detalle del donante' : nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final detalle in detalles) ...[
                Text(
                  detalle.key,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  detalle.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _valorDetalle(dynamic valor, {String valorVacio = 'No registrado'}) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? valorVacio : texto;
  }

  void _irARegistroDonante() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroDonanteScreen()),
    );
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
          final rutBuscado = DonanteRepository.normalizarRut(_filtroRut);
          final donantesFiltrados = donantes.where((donante) {
            final rutDonante = DonanteRepository.normalizarRut(
              (donante['rut'] ?? '').toString(),
            );
            return rutDonante.contains(rutBuscado);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por RUT',
                    hintText: 'Ingresa el RUT del donante',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filtroRut.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () => setState(() => _filtroRut = ''),
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (valor) => setState(() => _filtroRut = valor),
                ),
              ),
              Expanded(
                child: donantesFiltrados.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                donantes.isEmpty
                                    ? 'Aún no hay donantes registrados.'
                                    : 'No se encontraron donantes para ese RUT.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _irARegistroDonante,
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('Registrar donante'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: donantesFiltrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final donante = donantesFiltrados[index];
                          final nombre = (donante['nombre'] ?? '')
                              .toString()
                              .trim();
                          final rut = (donante['rut'] ?? '').toString().trim();

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                nombre.isEmpty ? 'Sin nombre' : nombre,
                              ),
                              subtitle: Text(
                                'RUT: ${rut.isEmpty ? 'Sin RUT' : rut}',
                              ),
                              onTap: () =>
                                  _mostrarDetalleDonante(context, donante),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
