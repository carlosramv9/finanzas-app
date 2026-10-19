import '../entities/movimiento.dart';
import '../entities/movimiento_filtro.dart';

abstract interface class MovimientosRepository {
  Future<Pagina<Movimiento>> listar(
    MovimientoFiltro filtro, {
    int offset = 0,
    int limite = 50,
  });

  Future<Movimiento> obtener(int id);

  Future<Movimiento> crear(MovimientoInput input);

  /// Solo se envían los campos editables permitidos por el servidor.
  Future<Movimiento> actualizar(Movimiento original, MovimientoInput input);

  /// Fecha del último movimiento que entró por correo (conector de Claude).
  Future<DateTime?> ultimoRegistroPorCorreo();

  /// CSV generado por el servidor en una sola petición.
  Future<String> exportarCsv();
}
