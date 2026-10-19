import '../../../../core/utils/periodo.dart';
import '../../domain/entities/cuenta.dart';
import '../../domain/repositories/cuentas_repository.dart';
import '../datasources/cuentas_remote_datasource.dart';

class CuentasRepositoryImpl implements CuentasRepository {
  CuentasRepositoryImpl(this._remote);

  final CuentasRemoteDataSource _remote;

  @override
  Future<List<Cuenta>> listar() async =>
      (await _remote.listar()).map(_fromJson).toList(growable: false);

  @override
  Future<List<CuentaConConteo>> conConteo(Periodo periodo) async => [
        for (final j in await _remote.conConteo(periodo))
          CuentaConConteo(_fromJson(j), (j['movimientos'] as num).toInt()),
      ];

  @override
  Future<Cuenta> guardar(Cuenta c) async {
    final body = {
      'nombre': c.nombre.trim(),
      'tipo': c.tipo.name,
      'moneda': c.moneda,
      'color': '#${(c.color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      'ultimos4': c.ultimos4,
      'remitente': (c.remitente?.trim().isEmpty ?? true) ? null : c.remitente!.trim(),
    };
    final row = c.id == 0
        ? await _remote.crear(body)
        : await _remote.actualizar(c.id, body);
    return _fromJson(row);
  }

  static Cuenta _fromJson(Map<String, dynamic> j) => Cuenta(
        id: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String,
        tipo: TipoCuenta.values.byName(j['tipo'] as String),
        moneda: j['moneda'] as String? ?? 'MXN',
        color: _parseColor(j['color'] as String?),
        ultimos4: j['ultimos4'] as String?,
        remitente: j['remitente'] as String?,
      );

  static int _parseColor(String? hex) {
    final v = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
    return v == null ? 0xFF56635D : 0xFF000000 | v;
  }
}
