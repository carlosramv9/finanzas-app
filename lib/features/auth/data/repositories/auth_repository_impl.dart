import 'dart:async';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/oauth_browser_datasource.dart';
import '../datasources/neon_auth_remote_datasource.dart';
import '../datasources/session_store.dart';
import '../models/neon_auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required NeonAuthRemoteDataSource remote,
    required OAuthBrowserDataSource browser,
    required SessionStore store,
  })  : _remote = remote, // ignore: prefer_initializing_formals
        _browser = browser, // ignore: prefer_initializing_formals
        _store = store; // ignore: prefer_initializing_formals

  final NeonAuthRemoteDataSource _remote;
  final OAuthBrowserDataSource _browser;
  final SessionStore _store;
  final _expired = StreamController<void>.broadcast();

  NeonSession? _session;

  /// Refresco en vuelo compartido: N peticiones concurrentes → 1 llamada.
  Future<NeonSession?>? _refreshing;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<AppUser?> restoreSession() async => (await _refresh())?.user;

  @override
  Future<AppUser> signInWithGoogle() async {
    final start = await _remote.startSocialSignIn(
      provider: 'google',
      callbackUrl: _browser.callbackUrl,
    );
    final verifier = await _browser.authorize(start.url);
    final result = await _remote.getSession(start.cookies, verifier: verifier);
    if (result == null) {
      throw const AppFailure('No se pudo completar el inicio de sesión.');
    }
    await _store.writeCookies(result.cookies);
    _session = result.session;
    return result.session.user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cookies = await _remote.signInWithEmail(email.trim(), password);
    return _establish(cookies);
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      _remote.requestPasswordReset(email.trim());

  @override
  Future<void> signOut() async {
    final cookies = await _store.readCookies();
    await _remote.signOut(cookies);
    await _store.clear();
    _session = null;
  }

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    final current = _session;
    if (!forceRefresh && current != null && current.isFresh) return current.jwt;
    return (await _refresh())?.jwt;
  }

  @override
  Future<void> onUnauthorized() async {
    await _store.clear();
    _session = null;
    _expired.add(null);
  }

  Future<AppUser> _establish(Map<String, String> cookies) async {
    await _store.writeCookies(cookies);
    final session = await _refresh();
    if (session == null) {
      throw const AppFailure('No se pudo establecer la sesión.');
    }
    return session.user;
  }

  Future<NeonSession?> _refresh() => _refreshing ??= () async {
        try {
          final cookies = await _store.readCookies();
          if (cookies.isEmpty) return _session = null;
          final result = await _remote.getSession(cookies);
          if (result == null) {
            await _store.clear();
            return _session = null;
          }
          await _store.writeCookies(result.cookies);
          return _session = result.session;
        } finally {
          _refreshing = null;
        }
      }();
}
