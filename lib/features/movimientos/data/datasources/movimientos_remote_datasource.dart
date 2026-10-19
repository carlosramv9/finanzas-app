import '../../../../core/network/data_api_client.dart';
import '../../domain/entities/movimiento_filtro.dart';

class MovimientosRemoteDataSource {
  MovimientosRemoteDataSource(this._api);

  final DataApiClient _api;
  static const _tabla = 'movimientos';

  /// Una sola petición con filtros + orden + paginación por offset.
  /// Se pide `limite + 1` para saber si hay otra página sin un COUNT(*).
  Future<List<Map<String, dynamic>>> listar(
    MovimientoFiltro f, {
    required String columnas,
    required int offset,
    required int limite,
  }) =>
      _api.select(_tabla, query: {
        'select': columnas,
        ..._filtros(f),
        'order': 'fecha.desc,id.desc',
        'offset': '$offset',
        'limit': '${limite + 1}',
      });

  Future<Map<String, dynamic>?> obtener(int id, String columnas) async {
    final rows = await _api.select(_tabla, query: {
      'select': columnas,
      'id': 'eq.$id',
      'limit': '1',
    });
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>> crear(Map<String, Object?> body, String columnas) =>
      _api.insert(_tabla, body, select: columnas);

  Future<Map<String, dynamic>> actualizar(
    int id,
    Map<String, Object?> body,
    String columnas,
  ) =>
      _api.update(_tabla, filters: {'id': 'eq.$id'}, body: body, select: columnas);

  Future<String?> ultimaFechaPorCorreo() async {
    final rows = await _api.select(_tabla, query: {
      'select': 'creado_en',
      'origen': 'eq.correo',
      'order': 'creado_en.desc',
      'limit': '1',
    });
    return rows.isEmpty ? null : rows.first['creado_en'] as String?;
  }

  Future<String> exportarCsv() => _api.selectCsv(_tabla, query: {
        'select': 'fecha,tipo,monto,moneda,concepto,categoria,cuenta,origen,notas',
        'order': 'fecha.desc',
      });

  static Map<String, Object> _filtros(MovimientoFiltro f) {
    final texto = f.texto?.replaceAll(RegExp(r'[*,()"\\]'), ' ').trim();
    return {
      if (f.tipo != null) 'tipo': 'eq.${f.tipo!.name}',
      if (f.categoria != null) 'categoria': 'eq.${f.categoria}',
      if (texto != null && texto.isNotEmpty) 'concepto': 'ilike.*$texto*',
      if (f.periodo != null)
        'fecha': ['gte.${f.periodo!.desdeIso}', 'lt.${f.periodo!.hastaIso}'],
    };
  }
}
