import 'package:intl/intl.dart';

abstract final class Fmt {
  static const _locale = 'es_MX';
  static final _money = NumberFormat.currency(locale: _locale, symbol: r'$');
  static final _mesAnio = DateFormat('MMMM y', _locale);
  static final _diaLargo = DateFormat("EEEE d MMM", _locale);
  static final _diaCorto = DateFormat('d MMM', _locale);
  static final _hora = DateFormat('HH:mm', _locale);
  static final _mesMeta = DateFormat('MMMM y', _locale);

  /// 123456 centavos → "$1,234.56"
  static String money(int centavos) => _money.format(centavos.abs() / 100);

  /// Monto con signo tipográfico: "+$1.00" / "−$1.00".
  static String signed(int centavos, {required bool esAbono}) =>
      '${esAbono ? '+' : '−'}${money(centavos)}';

  static String mesAnio(DateTime d) => _capitalize(_mesAnio.format(d));

  static String mesMeta(DateTime d) => _mesMeta.format(d);

  /// Encabezado de día: "Hoy", "Ayer", "Jueves 16 oct".
  static String encabezadoDia(DateTime d, {DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final dia = _soloFecha(d);
    final diff = hoy.difference(dia).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return _capitalize(_diaLargo.format(d));
  }

  /// Detalle corto: "Hoy 14:32", "Ayer", "16 oct".
  static String fechaCorta(DateTime d, {DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final diff = hoy.difference(_soloFecha(d)).inDays;
    if (diff == 0) return 'Hoy ${_hora.format(d)}';
    if (diff == 1) return 'Ayer';
    return _diaCorto.format(d);
  }

  /// Convierte texto "1,234.5" a centavos. Null si inválido o ≤ 0.
  static int? parseCentavos(String input) {
    final limpio = input.replaceAll(',', '').replaceAll(r'$', '').trim();
    final valor = double.tryParse(limpio);
    if (valor == null || valor <= 0) return null;
    return (valor * 100).round();
  }

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
