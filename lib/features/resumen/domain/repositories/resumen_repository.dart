import '../../../../core/utils/periodo.dart';
import '../entities/resumen_periodo.dart';

abstract interface class ResumenRepository {
  /// Totales + desglose por categoría calculados en Postgres (1 petición).
  Future<ResumenPeriodo> resumen(Periodo periodo, {String moneda = 'MXN'});
}
