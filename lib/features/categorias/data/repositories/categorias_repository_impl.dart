import '../../../../core/utils/periodo.dart';
import '../../../../core/utils/money_json.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/categorias_repository.dart';
import '../datasources/categorias_remote_datasource.dart';

class CategoriasRepositoryImpl implements CategoriasRepository {
  CategoriasRepositoryImpl(this._remote);

  final CategoriasRemoteDataSource _remote;

  @override
  Future<List<Categoria>> listar() async =>
      (await _remote.listar()).map(_fromJson).toList(growable: false);

  @override
  Future<List<CategoriaConTotal>> conTotales(Periodo periodo) async => [
        for (final j in await _remote.conTotales(periodo))
          CategoriaConTotal(
            categoria: _fromJson(j),
            totalCentavos: centavosFromJson(j['total']),
            movimientos: (j['movimientos'] as num).toInt(),
          ),
      ];

  @override
  Future<Categoria> crear(Categoria c) async => _fromJson(
        await _remote.crear({
          'nombre': c.nombre.trim(),
          'es_ingreso': c.esIngreso,
          'presupuesto': c.presupuestoCentavos == null
              ? null
              : centavosToJson(c.presupuestoCentavos!),
        }),
      );

  static Categoria _fromJson(Map<String, dynamic> j) => Categoria(
        nombre: j['nombre'] as String,
        esIngreso: j['es_ingreso'] as bool? ?? false,
        presupuestoCentavos:
            j['presupuesto'] == null ? null : centavosFromJson(j['presupuesto']),
      );
}
