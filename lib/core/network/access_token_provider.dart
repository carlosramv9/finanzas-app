/// Fuente del JWT que exige Neon Data API. La implementa la capa de auth.
abstract interface class AccessTokenProvider {
  /// JWT vigente o null si no hay sesión. [forceRefresh] ignora la caché.
  Future<String?> accessToken({bool forceRefresh = false});

  /// Se invoca cuando la Data API rechaza el token incluso tras refrescarlo.
  Future<void> onUnauthorized();
}
