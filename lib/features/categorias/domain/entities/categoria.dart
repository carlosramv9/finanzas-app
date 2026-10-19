class Categoria {
  const Categoria({
    required this.nombre,
    required this.esIngreso,
    this.presupuestoCentavos,
  });

  final String nombre;
  final bool esIngreso;
  final int? presupuestoCentavos;
}

/// Categoría con su total del periodo (resuelto con LEFT JOIN + GROUP BY).
class CategoriaConTotal {
  const CategoriaConTotal({
    required this.categoria,
    required this.totalCentavos,
    required this.movimientos,
  });

  final Categoria categoria;
  final int totalCentavos;
  final int movimientos;
}
