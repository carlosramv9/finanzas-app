class TotalCategoria {
  const TotalCategoria({
    required this.nombre,
    required this.totalCentavos,
    required this.movimientos,
  });

  final String nombre;
  final int totalCentavos;
  final int movimientos;
}

class ResumenPeriodo {
  const ResumenPeriodo({
    required this.abonosCentavos,
    required this.cargosCentavos,
    required this.porClasificar,
    required this.gastoPorCategoria,
  });

  final int abonosCentavos;
  final int cargosCentavos;

  /// Movimientos en la categoría comodín ("Otros") pendientes de revisar.
  final int porClasificar;

  /// Ordenado de mayor a menor gasto.
  final List<TotalCategoria> gastoPorCategoria;

  int get balanceCentavos => abonosCentavos - cargosCentavos;
}
