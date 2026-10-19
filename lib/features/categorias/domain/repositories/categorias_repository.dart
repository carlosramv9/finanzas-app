import '../../../../core/utils/periodo.dart';
import '../entities/categoria.dart';

abstract interface class CategoriasRepository {
  Future<List<Categoria>> listar();

  Future<List<CategoriaConTotal>> conTotales(Periodo periodo);

  Future<Categoria> crear(Categoria categoria);
}
