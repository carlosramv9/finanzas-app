import 'package:finanzas/core/utils/formatters.dart';
import 'package:finanzas/core/utils/money_json.dart';
import 'package:finanzas/core/utils/periodo.dart';
import 'package:finanzas/features/metas/domain/entities/meta.dart';
import 'package:finanzas/features/movimientos/data/models/movimiento_model.dart';
import 'package:finanzas/features/movimientos/domain/entities/movimiento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  group('dinero', () {
    test('centavos desde numeric en número o texto', () {
      expect(centavosFromJson(260.54), 26054);
      expect(centavosFromJson('17500.00'), 1750000);
      expect(centavosFromJson(null), 0);
    });

    test('formato con signo tipográfico', () {
      expect(Fmt.signed(18000, esAbono: false), '−\$180.00');
      expect(Fmt.signed(1750000, esAbono: true), '+\$17,500.00');
    });

    test('parseCentavos rechaza vacíos y no positivos', () {
      expect(Fmt.parseCentavos('1,236.40'), 123640);
      expect(Fmt.parseCentavos('0'), isNull);
      expect(Fmt.parseCentavos('abc'), isNull);
    });
  });

  test('encabezado de día relativo', () {
    final ahora = DateTime(2026, 10, 18, 15);
    expect(Fmt.encabezadoDia(DateTime(2026, 10, 18, 9), ahora: ahora), 'Hoy');
    expect(Fmt.encabezadoDia(DateTime(2026, 10, 17, 9), ahora: ahora), 'Ayer');
    expect(Fmt.encabezadoDia(DateTime(2026, 10, 16), ahora: ahora), 'Viernes 16 oct');
  });

  test('Periodo.mes cubre el mes completo, semiabierto', () {
    final p = Periodo.mes(DateTime(2026, 12, 18));
    expect(p.desde, DateTime(2026, 12));
    expect(p.hasta, DateTime(2027));
  });

  group('MovimientoModel.patchJson', () {
    final original = Movimiento(
      id: 1,
      tipo: TipoMovimiento.cargo,
      montoCentavos: 26054,
      moneda: 'MXN',
      fecha: DateTime.utc(2026, 10, 18, 22, 32),
      concepto: 'Uber Eats',
      categoria: 'Comida',
      origen: OrigenMovimiento.correo,
      cuenta: '6479',
      idCorreo: 'abc',
    );

    MovimientoInput input({TipoMovimiento tipo = TipoMovimiento.cargo, String categoria = 'Comida'}) =>
        MovimientoInput(
          tipo: tipo,
          montoCentavos: 26054,
          fecha: original.fecha,
          concepto: 'Uber Eats',
          categoria: categoria,
          cuenta: '6479',
        );

    test('sin cambios → patch vacío (no hay petición)', () {
      expect(MovimientoModel.patchJson(original, input()), isEmpty);
    });

    test('solo envía los campos modificados', () {
      expect(
        MovimientoModel.patchJson(original, input(categoria: 'Supermercado')),
        {'categoria': 'Supermercado'},
      );
    });

    test('de correo: nunca envía tipo', () {
      expect(
        MovimientoModel.patchJson(original, input(tipo: TipoMovimiento.abono)),
        isNot(contains('tipo')),
      );
    });

    test('alta manual fuerza origen manual', () {
      final json = MovimientoModel.insertJson(input());
      expect(json['origen'], 'manual');
      expect(json.containsKey('id_correo'), isFalse);
    });
  });

  test('Meta: progreso y aporte mensual sugerido', () {
    final meta = Meta(
      id: 1,
      nombre: 'Fondo',
      objetivoCentavos: 5000000,
      ahorradoCentavos: 3400000,
      fechaMeta: DateTime(2027, 6),
    );
    expect(meta.progreso, closeTo(0.68, 1e-9));
    expect(meta.aporteMensualSugerido(hoy: DateTime(2026, 10, 18)), 200000);
  });
}
