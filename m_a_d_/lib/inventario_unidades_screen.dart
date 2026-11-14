import 'package:flutter/material.dart';
import 'package:m_a_d_/repositories/unidad_repository.dart';

class InventarioUnidadesScreen extends StatefulWidget {
  const InventarioUnidadesScreen({super.key});

  @override
  State<InventarioUnidadesScreen> createState() =>
      _InventarioUnidadesScreenState();
}

class _InventarioUnidadesScreenState extends State<InventarioUnidadesScreen> {
  List _unidades = [];
  List _unidadesFiltradas = [];
  bool _estaCargando = true;

  final TextEditingController _searchController = TextEditingController();
  String _tipoSangreSeleccionado = 'Todos';
  bool _soloDisponibles = true;

  final List<String> _tiposSangre = [
    'Todos',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    _cargarInventario();
    _searchController.addListener(_filtrarPorTexto);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarInventario() async {
    setState(() => _estaCargando = true);

    final tipoSangreFiltro =
        _tipoSangreSeleccionado == 'Todos' ? null : _tipoSangreSeleccionado;

    final resultados = await UnidadRepository.filtrarUnidades(
      tipoSangre: tipoSangreFiltro,
      soloDisponibles: _soloDisponibles,
    );

    if (mounted) {
      setState(() {
        _unidades = resultados;
        _filtrarPorTexto();
        _estaCargando = false;
      });
    }
  }

  void _filtrarPorTexto() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _unidadesFiltradas = List.from(_unidades);
      } else {
        _unidadesFiltradas = _unidades.where((unidad) {
          final rut = (unidad['rut_donante'] ?? '').toString().toLowerCase();
          final id = (unidad['id'] ?? '').toString().toLowerCase();
          final sede = (unidad['sede'] ?? '').toString().toLowerCase();
          return rut.contains(query) || id.contains(query) || sede.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int cantidadPorVencer = _unidadesFiltradas.where((item) {
      return UnidadRepository.estaPorVencer(
        Map<String, dynamic>.from(item as Map),
      );
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario de Unidades'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Panel Superior de Filtros y Búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID, RUT o Sede...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de sangre',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        initialValue: _tipoSangreSeleccionado,
                        items: _tiposSangre.map((tipo) {
                          return DropdownMenuItem(
                              value: tipo, child: Text(tipo));
                        }).toList(),
                        onChanged: (nuevoValor) {
                          if (nuevoValor != null) {
                            setState(
                                () => _tipoSangreSeleccionado = nuevoValor);
                            _cargarInventario();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text('Solo disponibles',
                            style: TextStyle(fontSize: 11)),
                        Switch(
                          value: _soloDisponibles,
                          activeThumbColor: Colors.red.shade700,
                          onChanged: (valor) {
                            setState(() => _soloDisponibles = valor);
                            _cargarInventario();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notificación visual superior de unidades por vencer en NARANJA (Task12)
          if (!_estaCargando && cantidadPorVencer > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade400, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade900,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cantidadPorVencer == 1
                          ? 'Alerta: 1 unidad por vencer en los próximos 7 días.'
                          : 'Alerta: $cantidadPorVencer unidades por vencer en los próximos 7 días.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tabla con ocupación de ancho completo gracias a LayoutBuilder y ConstrainedBox
          Expanded(
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator())
                : _unidadesFiltradas.isEmpty
                    ? _construirPantallaVacia()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade200),
                                  columns: const [
                                    DataColumn(
                                        label: Text('ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Tipo',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('RUT Donante',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Estado',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Volumen',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Sede',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Extracción',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Caducidad',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _unidadesFiltradas.map((item) {
                                    final unidad = Map<String, dynamic>.from(
                                      item as Map,
                                    );
                                    final bool vencida =
                                        unidad['estado'] == 'Vencida';
                                    final bool porVencer =
                                        UnidadRepository.estaPorVencer(unidad);
                                    final int diasRestantes = porVencer
                                        ? UnidadRepository.diasParaVencer(
                                            unidad['fecha_caducidad'] as String,
                                          )
                                        : 0;

                                    // Rojo para vencidas, Naranja para próximas a vencer
                                    WidgetStateProperty<Color?>? rowColor;
                                    if (vencida) {
                                      rowColor = WidgetStateProperty.all(
                                          Colors.red.shade100);
                                    } else if (porVencer) {
                                      rowColor = WidgetStateProperty.all(
                                          Colors.orange.shade100);
                                    }

                                    return DataRow(
                                      color: rowColor,
                                      cells: [
                                        DataCell(Text('#${unidad['id']}')),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              unidad['tipo_sangre'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(unidad['rut_donante'] ?? ''),
                                        ),
                                        DataCell(Text(unidad['estado'] ?? '')),
                                        DataCell(
                                          Text('${unidad['volumen']} ml'),
                                        ),
                                        DataCell(Text(unidad['sede'] ?? '')),
                                        DataCell(
                                          Text(
                                              unidad['fecha_extraccion'] ?? ''),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (vencida) ...[
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.shade900,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                              ] else if (porVencer) ...[
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.orange.shade900,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                unidad['fecha_caducidad'] ?? '',
                                                style: TextStyle(
                                                  fontWeight:
                                                      (vencida || porVencer)
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color: vencida
                                                      ? Colors.red.shade900
                                                      : porVencer
                                                          ? Colors
                                                              .orange.shade900
                                                          : Colors.black87,
                                                ),
                                              ),
                                              if (vencida) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      4,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Vencida',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (porVencer) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade800,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      4,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    diasRestantes == 0
                                                        ? 'Vence hoy'
                                                        : 'Por vencer ($diasRestantes d)',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _construirPantallaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay unidades de sangre registradas\nque coincidan con los filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}