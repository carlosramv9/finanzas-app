class Meta {
  const Meta({
    required this.id,
    required this.nombre,
    required this.objetivoCentavos,
    required this.ahorradoCentavos,
    this.fechaMeta,
  });

  final int id;
  final String nombre;
  final int objetivoCentavos;
  final int ahorradoCentavos;
  final DateTime? fechaMeta;

  double get progreso => objetivoCentavos <= 0
      ? 0
      : (ahorradoCentavos / objetivoCentavos).clamp(0, 1).toDouble();

  int get faltanteCentavos =>
      (objetivoCentavos - ahorradoCentavos).clamp(0, objetivoCentavos);

  /// Aporte mensual necesario para llegar a tiempo. Null si no aplica.
  int? aporteMensualSugerido({DateTime? hoy}) {
    final fecha = fechaMeta;
    if (fecha == null || faltanteCentavos == 0) return null;
    final h = hoy ?? DateTime.now();
    final meses = (fecha.year - h.year) * 12 + fecha.month - h.month;
    return (faltanteCentavos / (meses < 1 ? 1 : meses)).ceil();
  }
}
