import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../resumen/presentation/providers/resumen_providers.dart';
import '../../domain/entities/cuenta.dart';

final cuentasProvider = FutureProvider<List<Cuenta>>(
  (ref) => ref.watch(cuentasRepositoryProvider).listar(),
);

final cuentasConConteoProvider =
    FutureProvider.autoDispose<List<CuentaConConteo>>(
  (ref) => ref
      .watch(cuentasRepositoryProvider)
      .conConteo(ref.watch(periodoSeleccionadoProvider)),
);
