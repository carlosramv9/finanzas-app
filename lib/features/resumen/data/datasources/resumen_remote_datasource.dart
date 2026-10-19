import '../../../../core/network/data_api_client.dart';
import '../../../../core/utils/periodo.dart';

class ResumenRemoteDataSource {
  ResumenRemoteDataSource(this._api);

  final DataApiClient _api;

  /// RPC `app_resumen_periodo` (ver db/migrations): un GROUP BY en el servidor.
  Future<Map<String, dynamic>> resumen(Periodo p, String moneda) =>
      _api.rpc<Map<String, dynamic>>('app_resumen_periodo', {
        'p_desde': p.desdeIso,
        'p_hasta': p.hastaIso,
        'p_moneda': moneda,
      });
}
