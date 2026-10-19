import '../../../../core/network/access_token_provider.dart';
import '../entities/app_user.dart';

abstract interface class AuthRepository implements AccessTokenProvider {
  /// Recupera la sesión guardada en el dispositivo (null si no hay o expiró).
  Future<AppUser?> restoreSession();

  /// OAuth con Google en el navegador del sistema → sesión de Neon Auth.
  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> signOut();

  /// Emite cuando la sesión se invalida desde fuera (p. ej. 401 persistente).
  Stream<void> get sessionExpired;
}
