import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../models/neon_auth_models.dart';

/// Endpoints REST de Neon Auth (Managed Better Auth).
///
/// La sesión vive en cookies; el JWT para Data API se obtiene en la cabecera
/// `set-auth-jwt` de `GET /get-session`.
class NeonAuthRemoteDataSource {
  NeonAuthRemoteDataSource({required String baseUrl, String? origin})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              'Content-Type': 'application/json',
              if (origin != null && origin.isNotEmpty) 'Origin': origin,
            },
          ),
        );

  final Dio _dio;

  /// Inicia OAuth. Devuelve la URL a abrir en el navegador y la cookie
  /// `session_challenge`, necesaria para canjear el verifier del callback.
  Future<({String url, Map<String, String> cookies})> startSocialSignIn({
    required String provider,
    required String callbackUrl,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/sign-in/social', data: {
        'provider': provider,
        'callbackURL': callbackUrl,
      });
      final url = res.data?['url'] as String?;
      final cookies = _parseSetCookie(res.headers);
      if (url == null || cookies.isEmpty) {
        throw const AppFailure('Neon Auth no inició el flujo OAuth.');
      }
      return (url: url, cookies: cookies);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] == 'INVALID_CALLBACKURL') {
        throw AppFailure(
          'Agrega "${Uri.parse(callbackUrl).origin}" a Trusted domains en Neon Auth.',
          statusCode: e.response?.statusCode,
        );
      }
      throw AppFailure.from(e);
    }
  }

  Future<Map<String, String>> signInWithEmail(String email, String password) =>
      _postForCookies('/sign-in/email', {
        'email': email,
        'password': password,
      });

  /// Sesión actual + JWT. Null si las cookies ya no son válidas.
  /// Con [verifier] canjea el callback OAuth por la cookie de sesión.
  Future<({NeonSession session, Map<String, String> cookies})?> getSession(
    Map<String, String> cookies, {
    String? verifier,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>?>(
        '/get-session',
        queryParameters: {
          'neon_auth_session_verifier': ?verifier,
        },
        options: Options(headers: {'Cookie': _cookieHeader(cookies)}),
      );
      final body = res.data;
      final jwt = res.headers.value('set-auth-jwt');
      if (body == null || body['user'] == null || jwt == null) return null;
      return (
        session: NeonSession(
          user: NeonUserModel.fromJson(body['user'] as Map<String, dynamic>),
          jwt: jwt,
        ),
        // Better Auth puede rotar la cookie al extender la sesión.
        cookies: {...cookies, ..._parseSetCookie(res.headers)},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw AppFailure.from(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post<void>('/request-password-reset', data: {'email': email});
    } on DioException catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> signOut(Map<String, String> cookies) async {
    try {
      await _dio.post<void>(
        '/sign-out',
        data: const <String, Object>{},
        options: Options(headers: {'Cookie': _cookieHeader(cookies)}),
      );
    } on DioException {
      // La sesión local se borra de todos modos.
    }
  }

  Future<Map<String, String>> _postForCookies(
    String path,
    Map<String, Object> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      final cookies = _parseSetCookie(res.headers);
      if (cookies.isEmpty) {
        throw const AppFailure('Neon Auth no devolvió una sesión.');
      }
      return cookies;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 400) {
        final data = e.response?.data;
        final msg = data is Map ? data['message']?.toString() : null;
        throw AppFailure(msg ?? 'Credenciales inválidas.', statusCode: status);
      }
      throw AppFailure.from(e);
    }
  }

  static Map<String, String> _parseSetCookie(Headers headers) {
    final result = <String, String>{};
    for (final raw in headers['set-cookie'] ?? const <String>[]) {
      final pair = raw.split(';').first;
      final idx = pair.indexOf('=');
      if (idx <= 0) continue;
      final name = pair.substring(0, idx).trim();
      final value = pair.substring(idx + 1).trim();
      if (value.isEmpty) {
        result.remove(name);
      } else {
        result[name] = value;
      }
    }
    return result;
  }

  static String _cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
}
