import '../../../../core/utils/money_json.dart';
import '../../domain/entities/movimiento.dart';

abstract final class MovimientoModel {
  /// Columnas explícitas: nunca `select=*` en listas.
  static const columnas =
      'id,tipo,monto,moneda,fecha,concepto,categoria,cuenta,cuenta_id,origen,id_correo,notas';

  static Movimiento fromJson(Map<String, dynamic> j) => Movimiento(
        id: (j['id'] as num).toInt(),
        tipo: TipoMovimiento.values.byName(j['tipo'] as String),
        montoCentavos: centavosFromJson(j['monto']),
        moneda: j['moneda'] as String? ?? 'MXN',
        fecha: DateTime.parse(j['fecha'] as String).toLocal(),
        concepto: j['concepto'] as String,
        categoria: j['categoria'] as String,
        origen: OrigenMovimiento.values.byName(j['origen'] as String),
        cuenta: j['cuenta'] as String?,
        cuentaId: (j['cuenta_id'] as num?)?.toInt(),
        idCorreo: j['id_correo'] as String?,
        notas: j['notas'] as String?,
      );

  static Map<String, Object?> insertJson(MovimientoInput i) => {
        'tipo': i.tipo.name,
        'origen': OrigenMovimiento.manual.name,
        ..._editable(i),
        'moneda': i.moneda,
        'cuenta': i.cuenta,
        'cuenta_id': i.cuentaId,
      };

  /// Diferencias contra el original (solo campos que el servidor permite).
  static Map<String, Object?> patchJson(Movimiento o, MovimientoInput i) {
    final next = _editable(i);
    final prev = {
      'monto': centavosToJson(o.montoCentavos),
      'fecha': o.fecha.toUtc().toIso8601String(),
      'concepto': o.concepto,
      'categoria': o.categoria,
      'notas': o.notas,
    };
    final diff = {
      for (final e in next.entries)
        if (prev[e.key] != e.value) e.key: e.value,
    };
    if (!o.tipoBloqueado) {
      if (i.tipo != o.tipo) diff['tipo'] = i.tipo.name;
      if (i.cuenta != o.cuenta) diff['cuenta'] = i.cuenta;
      if (i.cuentaId != o.cuentaId) diff['cuenta_id'] = i.cuentaId;
    }
    return diff;
  }

  static Map<String, Object?> _editable(MovimientoInput i) => {
        'monto': centavosToJson(i.montoCentavos),
        'fecha': i.fecha.toUtc().toIso8601String(),
        'concepto': i.concepto.trim(),
        'categoria': i.categoria,
        'notas': (i.notas?.trim().isEmpty ?? true) ? null : i.notas!.trim(),
      };

}
