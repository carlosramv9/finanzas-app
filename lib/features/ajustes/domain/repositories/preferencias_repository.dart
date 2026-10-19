import '../entities/preferencias.dart';

abstract interface class PreferenciasRepository {
  Preferencias leer();
  Future<void> guardar(Preferencias preferencias);
}
