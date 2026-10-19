import '../../../../core/utils/periodo.dart';
import '../../../../core/utils/money_json.dart';
import '../../domain/entities/resumen_periodo.dart';
import '../../domain/repositories/resumen_repository.dart';
import '../datasources/resumen_remote_datasource.dart';

class ResumenRepositoryImpl implements ResumenRepository {
  ResumenRepositoryImpl(this._remote);

  final ResumenRemoteDataSource _remote;

  @override
  Future<ResumenPeriodo> resumen(Periodo periodo, {String moneda = 'MXN'}) async {
    final j = await _remote.resumen(periodo, moneda);
    final cats = (j['categorias'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return ResumenPeriodo(
      abonosCentavos: centavosFromJson(j['abonos']),
      cargosCentavos: centavosFromJson(j['cargos']),
      porClasificar: (j['por_clasificar'] as num?)?.toInt() ?? 0,
      gastoPorCategoria: [
        for (final c in cats)
          TotalCategoria(
            nombre: c['nombre'] as String,
            totalCentavos: centavosFromJson(c['total']),
            movimientos: (c['movimientos'] as num).toInt(),
          ),
      ],
    );
  }
}
