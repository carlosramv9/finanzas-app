import 'dart:convert';

import '../../domain/entities/app_user.dart';

abstract final class NeonUserModel {
  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        image: json['image'] as String?,
      );
}

/// Sesión vigente: usuario + JWT para Data API.
class NeonSession {
  const NeonSession({required this.user, required this.jwt});

  final AppUser user;
  final String jwt;

  /// Expiración (`exp`) leída del payload del JWT.
  DateTime get expiresAt {
    try {
      final payload = jwt.split('.')[1];
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      ) as Map<String, dynamic>;
      return DateTime.fromMillisecondsSinceEpoch((json['exp'] as int) * 1000);
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isFresh =>
      expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 60)));
}
