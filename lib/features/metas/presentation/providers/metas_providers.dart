import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../domain/entities/meta.dart';

final metasProvider =
    AsyncNotifierProvider.autoDispose<MetasController, List<Meta>>(
  MetasController.new,
);

class MetasController extends AsyncNotifier<List<Meta>> {
  @override
  Future<List<Meta>> build() => ref.watch(metasRepositoryProvider).listar();

  Future<void> crear({
    required String nombre,
    required int objetivoCentavos,
    DateTime? fechaMeta,
  }) async {
    final meta = await ref.read(metasRepositoryProvider).crear(
          nombre: nombre,
          objetivoCentavos: objetivoCentavos,
          fechaMeta: fechaMeta,
        );
    state = AsyncData([...?state.value, meta]);
  }

  /// Reemplaza solo la meta afectada con la fila que devuelve la RPC.
  Future<void> aportar(int metaId, int montoCentavos) async {
    final meta = await ref.read(metasRepositoryProvider).aportar(metaId, montoCentavos);
    state = AsyncData([
      for (final m in state.value ?? const <Meta>[]) m.id == meta.id ? meta : m,
    ]);
  }
}
