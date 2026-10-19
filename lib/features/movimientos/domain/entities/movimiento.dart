enum TipoMovimiento {
  cargo,
  abono;

  bool get esAbono => this == abono;
}

enum OrigenMovimiento {
  correo,
  manual;

  String get etiqueta => this == correo ? 'Correo' : 'Manual';
}

class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.montoCentavos,
    required this.moneda,
    required this.fecha,
    required this.concepto,
    required this.categoria,
    required this.origen,
    this.cuenta,
    this.cuentaId,
    this.idCorreo,
    this.notas,
  });

  final int id;
  final TipoMovimiento tipo;
  final int montoCentavos;
  final String moneda;
  final DateTime fecha;
  final String concepto;
  final String categoria;
  final OrigenMovimiento origen;

  /// Últimos 4 dígitos, nunca el número completo.
  final String? cuenta;

  /// Cuenta del catálogo (incluye efectivo, que no tiene dígitos).
  final int? cuentaId;
  final String? idCorreo;
  final String? notas;

  /// Los registrados desde correo no permiten cambiar tipo/origen/id_correo.
  bool get tipoBloqueado => origen == OrigenMovimiento.correo;
}

/// Datos editables de un movimiento (alta o edición).
class MovimientoInput {
  const MovimientoInput({
    required this.tipo,
    required this.montoCentavos,
    required this.fecha,
    required this.concepto,
    required this.categoria,
    this.moneda = 'MXN',
    this.cuenta,
    this.cuentaId,
    this.notas,
  });

  final TipoMovimiento tipo;
  final int montoCentavos;
  final DateTime fecha;
  final String concepto;
  final String categoria;
  final String moneda;
  final String? cuenta;
  final int? cuentaId;
  final String? notas;
}
