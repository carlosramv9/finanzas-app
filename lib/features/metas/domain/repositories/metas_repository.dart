import '../entities/meta.dart';

abstract interface class MetasRepository {
  Future<List<Meta>> listar();

  Future<Meta> crear({
    required String nombre,
    required int objetivoCentavos,
    DateTime? fechaMeta,
  });

  /// Suma atómica en el servidor (sin leer-modificar-escribir en el cliente).
  Future<Meta> aportar(int metaId, int montoCentavos);
}
