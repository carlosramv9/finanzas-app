import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env.dart';
import '../core/network/data_api_client.dart';
import '../features/ajustes/data/repositories/preferencias_repository_impl.dart';
import '../features/ajustes/domain/repositories/preferencias_repository.dart';
import '../features/auth/data/datasources/biometric_datasource.dart';
import '../features/auth/data/datasources/oauth_browser_datasource.dart';
import '../features/auth/data/datasources/neon_auth_remote_datasource.dart';
import '../features/auth/data/datasources/session_store.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/categorias/data/datasources/categorias_remote_datasource.dart';
import '../features/categorias/data/repositories/categorias_repository_impl.dart';
import '../features/categorias/domain/repositories/categorias_repository.dart';
import '../features/cuentas/data/datasources/cuentas_remote_datasource.dart';
import '../features/cuentas/data/repositories/cuentas_repository_impl.dart';
import '../features/cuentas/domain/repositories/cuentas_repository.dart';
import '../features/metas/data/datasources/metas_remote_datasource.dart';
import '../features/metas/data/repositories/metas_repository_impl.dart';
import '../features/metas/domain/repositories/metas_repository.dart';
import '../features/movimientos/data/datasources/movimientos_remote_datasource.dart';
import '../features/movimientos/data/repositories/movimientos_repository_impl.dart';
import '../features/movimientos/domain/repositories/movimientos_repository.dart';
import '../features/resumen/data/datasources/resumen_remote_datasource.dart';
import '../features/resumen/data/repositories/resumen_repository_impl.dart';
import '../features/resumen/domain/repositories/resumen_repository.dart';

/// Raíz de composición: único lugar donde la capa de presentación obtiene
/// implementaciones concretas de data. Las pantallas solo ven interfaces de
/// dominio.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Se sobrescribe en main()'),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: NeonAuthRemoteDataSource(
      baseUrl: Env.neonAuthUrl,
      origin: Env.neonAuthOrigin,
    ),
    browser: const OAuthBrowserDataSource(
      callbackScheme: Env.oauthCallbackScheme,
      bridgeUrl: Env.oauthCallbackUrl,
    ),
    store: SessionStore(),
  ),
);

final biometricProvider = Provider<BiometricDataSource>(
  (ref) => BiometricDataSource(),
);

final dataApiClientProvider = Provider<DataApiClient>(
  (ref) => DataApiClient(
    baseUrl: Env.neonDataApiUrl,
    tokens: ref.watch(authRepositoryProvider),
  ),
);

final preferenciasRepositoryProvider = Provider<PreferenciasRepository>(
  (ref) => PreferenciasRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final movimientosRepositoryProvider = Provider<MovimientosRepository>(
  (ref) => MovimientosRepositoryImpl(
    MovimientosRemoteDataSource(ref.watch(dataApiClientProvider)),
  ),
);

final resumenRepositoryProvider = Provider<ResumenRepository>(
  (ref) => ResumenRepositoryImpl(
    ResumenRemoteDataSource(ref.watch(dataApiClientProvider)),
  ),
);

final categoriasRepositoryProvider = Provider<CategoriasRepository>(
  (ref) => CategoriasRepositoryImpl(
    CategoriasRemoteDataSource(ref.watch(dataApiClientProvider)),
  ),
);

final cuentasRepositoryProvider = Provider<CuentasRepository>(
  (ref) => CuentasRepositoryImpl(
    CuentasRemoteDataSource(ref.watch(dataApiClientProvider)),
  ),
);

final metasRepositoryProvider = Provider<MetasRepository>(
  (ref) => MetasRepositoryImpl(
    MetasRemoteDataSource(ref.watch(dataApiClientProvider)),
  ),
);
