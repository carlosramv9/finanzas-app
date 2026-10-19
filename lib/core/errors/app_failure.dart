import 'package:dio/dio.dart';

/// Error de dominio legible para la UI.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? detail;
      if (data is Map) {
        detail = (data['message'] ?? data['error'] ?? data['hint'])?.toString();
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          const AppFailure('La conexión tardó demasiado. Intenta de nuevo.'),
        DioExceptionType.connectionError =>
          const AppFailure('Sin conexión a internet.'),
        _ when status == 401 => const AppFailure(
            'Tu sesión expiró. Vuelve a iniciar sesión.',
            statusCode: 401,
          ),
        _ when status == 403 => const AppFailure(
            'Tu cuenta no tiene acceso a estos datos.',
            statusCode: 403,
          ),
        _ => AppFailure(
            detail ?? 'Error del servidor${status != null ? ' ($status)' : ''}.',
            statusCode: status,
          ),
      };
    }
    return AppFailure(error.toString());
  }

  @override
  String toString() => message;
}
