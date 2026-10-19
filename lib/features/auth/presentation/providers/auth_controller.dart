import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/app_user.dart';

enum AuthStatus { signedOut, locked, signedIn }

class AuthState {
  const AuthState(this.status, [this.user]);

  const AuthState.signedOut() : this(AuthStatus.signedOut);

  final AuthStatus status;
  final AppUser? user;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  StreamSubscription<void>? _expiredSub;

  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    _expiredSub?.cancel();
    _expiredSub = repo.sessionExpired.listen(
      (_) => state = const AsyncData(AuthState.signedOut()),
    );
    ref.onDispose(() => _expiredSub?.cancel());

    final user = await repo.restoreSession();
    if (user == null) return const AuthState.signedOut();
    final bio = ref.read(preferenciasRepositoryProvider).leer().desbloqueoBiometrico;
    return AuthState(bio ? AuthStatus.locked : AuthStatus.signedIn, user);
  }

  Future<void> signInWithGoogle() =>
      _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<void> signInWithEmail(String email, String password) => _run(
        () => ref
            .read(authRepositoryProvider)
            .signInWithEmail(email: email, password: password),
      );

  Future<void> requestPasswordReset(String email) =>
      ref.read(authRepositoryProvider).requestPasswordReset(email);

  /// Desbloqueo con huella / Face ID cuando hay sesión guardada.
  Future<bool> unlockWithBiometrics() async {
    final current = state.value;
    if (current?.status != AuthStatus.locked) return false;
    final ok = await ref.read(biometricProvider).autenticar();
    if (ok) state = AsyncData(AuthState(AuthStatus.signedIn, current!.user));
    return ok;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(AuthState.signedOut());
  }

  /// Lanza [AppFailure]; la pantalla muestra el error y su propio spinner.
  Future<void> _run(Future<AppUser> Function() action) async {
    try {
      final user = await action();
      state = AsyncData(AuthState(AuthStatus.signedIn, user));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
