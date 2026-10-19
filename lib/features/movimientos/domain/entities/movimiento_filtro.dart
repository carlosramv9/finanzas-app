import '../../../../core/utils/periodo.dart';
import 'movimiento.dart';

class MovimientoFiltro {
  const MovimientoFiltro({this.tipo, this.categoria, this.texto, this.periodo});

  final TipoMovimiento? tipo;
  final String? categoria;
  final String? texto;
  final Periodo? periodo;

  MovimientoFiltro copyWith({
    TipoMovimiento? Function()? tipo,
    String? Function()? categoria,
    String? Function()? texto,
    Periodo? Function()? periodo,
  }) =>
      MovimientoFiltro(
        tipo: tipo != null ? tipo() : this.tipo,
        categoria: categoria != null ? categoria() : this.categoria,
        texto: texto != null ? texto() : this.texto,
        periodo: periodo != null ? periodo() : this.periodo,
      );

  @override
  bool operator ==(Object other) =>
      other is MovimientoFiltro &&
      other.tipo == tipo &&
      other.categoria == categoria &&
      other.texto == texto &&
      other.periodo == periodo;

  @override
  int get hashCode => Object.hash(tipo, categoria, texto, periodo);
}

class Pagina<T> {
  const Pagina(this.items, {required this.hayMas});

  final List<T> items;
  final bool hayMas;
}
