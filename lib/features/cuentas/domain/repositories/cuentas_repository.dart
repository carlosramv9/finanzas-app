import '../../../../core/utils/periodo.dart';
import '../entities/cuenta.dart';

abstract interface class CuentasRepository {
  Future<List<Cuenta>> listar();

  /// Cuentas con número de movimientos del periodo, en una sola consulta.
  Future<List<CuentaConConteo>> conConteo(Periodo periodo);

  /// Crea si `id == 0`, actualiza en otro caso.
  Future<Cuenta> guardar(Cuenta cuenta);
}
