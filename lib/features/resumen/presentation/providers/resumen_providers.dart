import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../core/utils/periodo.dart';
import '../../../ajustes/presentation/providers/preferencias_controller.dart';
import '../../../movimientos/domain/entities/movimiento.dart';
import '../../../movimientos/domain/entities/movimiento_filtro.dart';
import '../../domain/entities/resumen_periodo.dart';

/// Mes que se consulta en Inicio, Categorías y Cuentas.
final mesSeleccionadoProvider =
    NotifierProvider<MesSeleccionado, DateTime>(MesSeleccionado.new);

class MesSeleccionado extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void elegir(DateTime mes) => state = DateTime(mes.year, mes.month);
}

final periodoSeleccionadoProvider = Provider<Periodo>(
  (ref) => Periodo.mes(ref.watch(mesSeleccionadoProvider)),
);

/// Resumen del mes: 1 RPC con totales + GROUP BY por categoría.
final resumenMesProvider = FutureProvider.autoDispose<ResumenPeriodo>((ref) {
  final periodo = ref.watch(periodoSeleccionadoProvider);
  final moneda = ref.watch(preferenciasProvider.select((p) => p.moneda));
  return ref.watch(resumenRepositoryProvider).resumen(periodo, moneda: moneda);
});

/// Últimos 4 movimientos: 1 SELECT con LIMIT.
final recientesProvider = FutureProvider.autoDispose<List<Movimiento>>((ref) async {
  final pagina = await ref
      .watch(movimientosRepositoryProvider)
      .listar(const MovimientoFiltro(), limite: 4);
  return pagina.items;
});
