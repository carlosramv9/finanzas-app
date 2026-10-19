import '../../../../core/network/data_api_client.dart';

class MetasRemoteDataSource {
  MetasRemoteDataSource(this._api);

  final DataApiClient _api;
  static const cols = 'id,nombre,objetivo,ahorrado,fecha_meta';

  Future<List<Map<String, dynamic>>> listar() => _api.select('metas', query: {
        'select': cols,
        'order': 'fecha_meta.asc.nullslast,id.asc',
      });

  Future<Map<String, dynamic>> crear(Map<String, Object?> body) =>
      _api.insert('metas', body, select: cols);

  Future<Map<String, dynamic>> aportar(int id, double monto) =>
      _api.rpc<Map<String, dynamic>>('app_aportar_meta', {
        'p_meta_id': id,
        'p_monto': monto,
      });
}
