import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/entities/movimiento_filtro.dart';
import '../../domain/repositories/movimientos_repository.dart';
import '../datasources/movimientos_remote_datasource.dart';
import '../models/movimiento_model.dart';

class MovimientosRepositoryImpl implements MovimientosRepository {
  MovimientosRepositoryImpl(this._remote);

  final MovimientosRemoteDataSource _remote;
  static const _cols = MovimientoModel.columnas;

  @override
  Future<Pagina<Movimiento>> listar(
    MovimientoFiltro filtro, {
    int offset = 0,
    int limite = 50,
  }) async {
    final rows = await _remote.listar(
      filtro,
      columnas: _cols,
      offset: offset,
      limite: limite,
    );
    final hayMas = rows.length > limite;
    return Pagina(
      rows.take(limite).map(MovimientoModel.fromJson).toList(growable: false),
      hayMas: hayMas,
    );
  }

  @override
  Future<Movimiento> obtener(int id) async {
    final row = await _remote.obtener(id, _cols);
    if (row == null) throw const AppFailure('El movimiento ya no existe.');
    return MovimientoModel.fromJson(row);
  }

  @override
  Future<Movimiento> crear(MovimientoInput input) async => MovimientoModel.fromJson(
        await _remote.crear(MovimientoModel.insertJson(input), _cols),
      );

  @override
  Future<Movimiento> actualizar(Movimiento original, MovimientoInput input) async {
    final patch = MovimientoModel.patchJson(original, input);
    if (patch.isEmpty) return original;
    return MovimientoModel.fromJson(
      await _remote.actualizar(original.id, patch, _cols),
    );
  }

  @override
  Future<DateTime?> ultimoRegistroPorCorreo() async {
    final iso = await _remote.ultimaFechaPorCorreo();
    return iso == null ? null : DateTime.parse(iso).toLocal();
  }

  @override
  Future<String> exportarCsv() => _remote.exportarCsv();
}
