import '../../../../core/network/data_api_client.dart';
import '../../../../core/utils/periodo.dart';

class CategoriasRemoteDataSource {
  CategoriasRemoteDataSource(this._api);

  final DataApiClient _api;
  static const _cols = 'nombre,es_ingreso,presupuesto';

  Future<List<Map<String, dynamic>>> listar() => _api.select('categorias', query: {
        'select': _cols,
        'order': 'es_ingreso.asc,nombre.asc',
      });

  Future<List<Map<String, dynamic>>> conTotales(Periodo p) async {
    final data = await _api.rpc<List<dynamic>>('app_categorias_con_totales', {
      'p_desde': p.desdeIso,
      'p_hasta': p.hastaIso,
    });
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> crear(Map<String, Object?> body) =>
      _api.insert('categorias', body, select: _cols);
}
