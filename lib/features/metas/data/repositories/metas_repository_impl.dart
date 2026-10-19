import '../../../../core/utils/money_json.dart';
import '../../domain/entities/meta.dart';
import '../../domain/repositories/metas_repository.dart';
import '../datasources/metas_remote_datasource.dart';

class MetasRepositoryImpl implements MetasRepository {
  MetasRepositoryImpl(this._remote);

  final MetasRemoteDataSource _remote;

  @override
  Future<List<Meta>> listar() async =>
      (await _remote.listar()).map(_fromJson).toList(growable: false);

  @override
  Future<Meta> crear({
    required String nombre,
    required int objetivoCentavos,
    DateTime? fechaMeta,
  }) async =>
      _fromJson(await _remote.crear({
        'nombre': nombre.trim(),
        'objetivo': centavosToJson(objetivoCentavos),
        'fecha_meta': fechaMeta == null
            ? null
            : '${fechaMeta.year.toString().padLeft(4, '0')}-'
                '${fechaMeta.month.toString().padLeft(2, '0')}-01',
      }));

  @override
  Future<Meta> aportar(int metaId, int montoCentavos) async =>
      _fromJson(await _remote.aportar(metaId, centavosToJson(montoCentavos)));

  static Meta _fromJson(Map<String, dynamic> j) => Meta(
        id: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String,
        objetivoCentavos: centavosFromJson(j['objetivo']),
        ahorradoCentavos: centavosFromJson(j['ahorrado']),
        fechaMeta: j['fecha_meta'] == null
            ? null
            : DateTime.parse(j['fecha_meta'] as String),
      );
}
