/// Configuración inyectada en compilación:
/// `flutter run --dart-define-from-file=env.json`
abstract final class Env {
  /// Auth URL de Neon Auth (Managed Better Auth), p. ej.
  /// https://ep-xxx.neonauth.us-east-1.aws.neon.tech/neondb/auth
  static const neonAuthUrl = String.fromEnvironment('NEON_AUTH_URL');

  /// REST endpoint de Neon Data API, p. ej.
  /// https://ep-xxx.apirest.us-east-1.aws.neon.tech/neondb/rest/v1
  static const neonDataApiUrl = String.fromEnvironment('NEON_DATA_API_URL');

  /// Origen de confianza registrado en Neon Auth (Trusted domains).
  /// Se envía como cabecera `Origin` porque las apps nativas no la tienen.
  static const neonAuthOrigin = String.fromEnvironment('NEON_AUTH_ORIGIN');

  /// Esquema del deep link de regreso a la app (`finanzas://auth`).
  /// Declarado en el AndroidManifest (CallbackActivity).
  static const oauthCallbackScheme = 'finanzas';

  /// Página puente https para el callback OAuth en release, p. ej.
  /// https://orbixmx.com/finanzas/auth — redirige a `finanzas://auth?…`.
  /// Vacío → callback loopback `http://localhost:43821/auth` (desarrollo).
  static const oauthCallbackUrl = String.fromEnvironment('NEON_AUTH_CALLBACK_URL');

  static List<String> get faltantes => [
        if (neonAuthUrl.isEmpty) 'NEON_AUTH_URL',
        if (neonDataApiUrl.isEmpty) 'NEON_DATA_API_URL',
      ];
}
