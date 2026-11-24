/// Representa una solicitud para despachar unidades a un centro médico.
class OrdenDespacho {
  /// Crea una orden nueva, pendiente por defecto y con IDs de unidades fijos.
  OrdenDespacho({
    required this.id,
    required this.fechaSolicitud,
    required this.sedeOrigen,
    required this.centroMedicoDestino,
    this.estado = 'Pendiente',
    required List<int> unidadesIds,
  }) : unidadesIds = List.unmodifiable(unidadesIds);

  /// Identificador único de la orden.
  final int id;

  /// Fecha y hora en que se solicitó el despacho.
  final DateTime fechaSolicitud;

  /// Sede desde la que se despachan las unidades.
  final String sedeOrigen;

  /// Centro médico que recibirá las unidades.
  final String centroMedicoDestino;

  /// Estado actual de la orden; inicialmente es `Pendiente`.
  final String estado;

  /// IDs de las unidades incluidas en el lote.
  final List<int> unidadesIds;

  /// Convierte la orden a un mapa con claves compatibles con JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha_solicitud': fechaSolicitud.toIso8601String(),
    'sede_origen': sedeOrigen,
    'centro_medico_destino': centroMedicoDestino,
    'estado': estado,
    'unidades_ids': unidadesIds,
  };

  /// Reconstruye una orden desde un mapa JSON con el esquema esperado.
  factory OrdenDespacho.fromJson(Map<String, dynamic> json) {
    return OrdenDespacho(
      id: json['id'] as int,
      fechaSolicitud: DateTime.parse(json['fecha_solicitud'] as String),
      sedeOrigen: json['sede_origen'] as String,
      centroMedicoDestino: json['centro_medico_destino'] as String,
      estado: json['estado'] as String,
      unidadesIds: (json['unidades_ids'] as List<dynamic>)
          .map((id) => id as int)
          .toList(),
    );
  }
}
