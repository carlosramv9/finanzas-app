import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../resumen/presentation/providers/resumen_providers.dart';
import '../../domain/entities/categoria.dart';

/// Catálogo en caché durante la sesión: se pide una vez y lo reutilizan el
/// formulario, los filtros y Ajustes.
final categoriasProvider = FutureProvider<List<Categoria>>(
  (ref) => ref.watch(categoriasRepositoryProvider).listar(),
);

final categoriasConTotalesProvider =
    FutureProvider.autoDispose<List<CategoriaConTotal>>(
  (ref) => ref
      .watch(categoriasRepositoryProvider)
      .conTotales(ref.watch(periodoSeleccionadoProvider)),
);
