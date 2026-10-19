import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../../core/errors/app_failure.dart';

/// OAuth en el navegador del sistema. Neon Auth solo acepta callbacks
/// http(s) en Trusted domains, así que el regreso a la app tiene dos modos:
///
/// * **Puente https** ([bridgeUrl], release): Neon redirige a
///   `https://orbixmx.com/finanzas/auth?neon_auth_session_verifier=…`, que
///   reenvía a `finanzas://auth?…` y cierra el navegador.
/// * **Loopback** (RFC 8252, desarrollo): un servidor efímero en 127.0.0.1
///   captura `http://localhost:<puerto>/auth?…` y responde 302 a `finanzas://auth`.
///
/// El verifier solo sirve junto con la cookie `session_challenge`, que nunca
/// sale de la app; interceptarlo no basta para robar la sesión.
class OAuthBrowserDataSource {
  const OAuthBrowserDataSource({
    required this.callbackScheme,
    this.bridgeUrl = '',
    this.loopbackPort = 43821,
  });

  final String callbackScheme;
  final String bridgeUrl;
  final int loopbackPort;

  bool get _usaPuente => bridgeUrl.isNotEmpty;

  /// Debe estar en Trusted domains de Neon Auth (su origen).
  String get callbackUrl =>
      _usaPuente ? bridgeUrl : 'http://localhost:$loopbackPort/auth';

  /// Devuelve el `neon_auth_session_verifier` del callback.
  Future<String> authorize(String url) =>
      _usaPuente ? _viaPuente(url) : _viaLoopback(url);

  Future<String> _viaPuente(String url) async {
    final result = await _abrir(url);
    final q = Uri.parse(result).queryParameters;
    return _verifierO(q['neon_auth_session_verifier'], q['error_description'] ?? q['error']);
  }

  Future<String> _viaLoopback(String url) async {
    final servers = await _bindLoopback();
    String? verifier;
    String? error;

    void handle(HttpRequest req) {
      if (req.uri.path != '/auth') {
        req.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }
      final q = req.uri.queryParameters;
      verifier = q['neon_auth_session_verifier'];
      error = q['error_description'] ?? q['error'];
      req.response
        ..statusCode = HttpStatus.found
        ..headers.set(HttpHeaders.locationHeader, '$callbackScheme://auth')
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
        ..close();
    }

    final subs = [for (final s in servers) s.listen(handle)];
    try {
      await _abrir(url);
    } finally {
      for (final s in subs) {
        await s.cancel();
      }
      for (final s in servers) {
        await s.close(force: true);
      }
    }
    return _verifierO(verifier, error);
  }

  Future<String> _abrir(String url) async {
    try {
      return await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackScheme,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw const AppFailure('Inicio de sesión cancelado.');
      }
      throw AppFailure('No se pudo abrir el inicio de sesión: ${e.message ?? e.code}');
    }
  }

  static String _verifierO(String? verifier, String? error) {
    if (verifier == null || verifier.isEmpty) {
      throw AppFailure(error ?? 'Neon Auth no devolvió la sesión.');
    }
    return verifier;
  }

  /// `localhost` puede resolverse a IPv4 o IPv6: se escucha en ambos.
  Future<List<HttpServer>> _bindLoopback() async {
    final servers = <HttpServer>[];
    for (final addr in [InternetAddress.loopbackIPv4, InternetAddress.loopbackIPv6]) {
      try {
        servers.add(await HttpServer.bind(addr, loopbackPort));
      } on SocketException {
        // IPv6 puede no estar disponible; basta con una interfaz.
      }
    }
    if (servers.isEmpty) {
      throw AppFailure('El puerto $loopbackPort está ocupado. Cierra otras apps e intenta de nuevo.');
    }
    return servers;
  }
}
