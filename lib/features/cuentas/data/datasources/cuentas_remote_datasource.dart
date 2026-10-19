import '../../../../core/network/data_api_client.dart';
import '../../../../core/utils/periodo.dart';

class CuentasRemoteDataSource {
  CuentasRemoteDataSource(this._api);

  final DataApiClient _api;
  static const cols = 'id,nombre,tipo,moneda,color,ultimos4,remitente';

  Future<List<Map<String, dynamic>>> listar() =>
      _api.select('cuentas', query: {'select': cols, 'order': 'id.asc'});

  Future<List<Map<String, dynamic>>> conConteo(Periodo p) async {
    final data = await _api.rpc<List<dynamic>>('app_cuentas_con_conteo', {
      'p_desde': p.desdeIso,
      'p_hasta': p.hastaIso,
    });
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> crear(Map<String, Object?> body) =>
      _api.insert('cuentas', body, select: cols);

  Future<Map<String, dynamic>> actualizar(int id, Map<String, Object?> body) =>
      _api.update('cuentas', filters: {'id': 'eq.$id'}, body: body, select: cols);
}
