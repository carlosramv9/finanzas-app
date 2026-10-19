enum TipoCuenta {
  debito('Débito'),
  credito('Crédito'),
  efectivo('Captura manual');

  const TipoCuenta(this.etiqueta);
  final String etiqueta;
}

class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.moneda,
    required this.color,
    this.ultimos4,
    this.remitente,
  });

  final int id;
  final String nombre;
  final TipoCuenta tipo;
  final String moneda;

  /// ARGB, p. ej. 0xFF0F5F4F.
  final int color;

  /// Solo los últimos 4 dígitos. Enlaza con `movimientos.cuenta`.
  final String? ultimos4;

  /// Remitente de las notificaciones bancarias, p. ej. alertas@banco.
  final String? remitente;

  String get etiquetaCorta =>
      ultimos4 == null ? nombre : '$nombre ••$ultimos4';
}

class CuentaConConteo {
  const CuentaConConteo(this.cuenta, this.movimientos);

  final Cuenta cuenta;
  final int movimientos;
}
