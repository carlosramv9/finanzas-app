import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste las cookies de sesión de Neon Auth en Keychain / Keystore.
class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'neon_auth_cookies';

  Future<Map<String, String>> readCookies() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
  }

  Future<void> writeCookies(Map<String, String> cookies) =>
      _storage.write(key: _key, value: jsonEncode(cookies));

  Future<void> clear() => _storage.delete(key: _key);
}
