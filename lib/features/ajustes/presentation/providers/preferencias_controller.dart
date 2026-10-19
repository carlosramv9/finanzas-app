import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../domain/entities/preferencias.dart';

final preferenciasProvider =
    NotifierProvider<PreferenciasController, Preferencias>(
  PreferenciasController.new,
);

class PreferenciasController extends Notifier<Preferencias> {
  @override
  Preferencias build() => ref.watch(preferenciasRepositoryProvider).leer();

  Future<void> actualizar(Preferencias Function(Preferencias) cambio) async {
    state = cambio(state);
    await ref.read(preferenciasRepositoryProvider).guardar(state);
  }

  /// Solo activa la biometría si el dispositivo la soporta y el usuario la valida.
  Future<bool> activarBiometria(bool activar) async {
    if (activar) {
      final bio = ref.read(biometricProvider);
      if (!await bio.disponible() || !await bio.autenticar()) return false;
    }
    await actualizar((p) => p.copyWith(desbloqueoBiometrico: activar));
    return true;
  }
}
