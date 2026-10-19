import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../categorias/presentation/providers/categorias_providers.dart';
import '../../../cuentas/presentation/providers/cuentas_providers.dart';
import '../../../resumen/presentation/providers/resumen_providers.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/entities/movimiento_filtro.dart';

final movimientosFiltroProvider =
    NotifierProvider<MovimientosFiltro, MovimientoFiltro>(MovimientosFiltro.new);

class MovimientosFiltro extends Notifier<MovimientoFiltro> {
  @override
  MovimientoFiltro build() => const MovimientoFiltro();

  void tipo(TipoMovimiento? t) => state = state.copyWith(tipo: () => t);
  void categoria(String? c) => state = state.copyWith(categoria: () => c);
  void texto(String t) =>
      state = state.copyWith(texto: () => t.trim().isEmpty ? null : t.trim());
  void soloCategoria(String c) => state = MovimientoFiltro(categoria: c);
}

class MovimientosListState {
  const MovimientosListState(this.items, {required this.hayMas, this.cargandoMas = false});

  final List<Movimiento> items;
  final bool hayMas;
  final bool cargandoMas;
}

final movimientosListProvider =
    AsyncNotifierProvider.autoDispose<MovimientosList, MovimientosListState>(
  MovimientosList.new,
);

/// Lista paginada: cada página es UNA consulta con filtros en el servidor.
class MovimientosList extends AsyncNotifier<MovimientosListState> {
  static const _pagina = 50;

  @override
  Future<MovimientosListState> build() async {
    final filtro = ref.watch(movimientosFiltroProvider);
    final p = await ref
        .watch(movimientosRepositoryProvider)
        .listar(filtro, limite: _pagina);
    return MovimientosListState(p.items, hayMas: p.hayMas);
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;
    state = AsyncData(
      MovimientosListState(actual.items, hayMas: true, cargandoMas: true),
    );
    try {
      final p = await ref.read(movimientosRepositoryProvider).listar(
            ref.read(movimientosFiltroProvider),
            offset: actual.items.length,
            limite: _pagina,
          );
      state = AsyncData(
        MovimientosListState([...actual.items, ...p.items], hayMas: p.hayMas),
      );
    } catch (_) {
      state = AsyncData(MovimientosListState(actual.items, hayMas: true));
      rethrow;
    }
  }
}

final movimientoPorIdProvider =
    FutureProvider.autoDispose.family<Movimiento, int>(
  (ref, id) => ref.watch(movimientosRepositoryProvider).obtener(id),
);

/// Tras crear/editar un movimiento, refresca todo lo que depende de él.
void invalidarDependientesDeMovimientos(WidgetRef ref) {
  ref
    ..invalidate(movimientosListProvider)
    ..invalidate(resumenMesProvider)
    ..invalidate(recientesProvider)
    ..invalidate(categoriasConTotalesProvider)
    ..invalidate(cuentasConConteoProvider);
}
