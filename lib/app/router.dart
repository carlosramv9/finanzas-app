import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ajustes/presentation/pages/ajustes_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/categorias/presentation/pages/categorias_page.dart';
import '../features/cuentas/presentation/pages/cuentas_page.dart';
import '../features/metas/presentation/pages/metas_page.dart';
import '../features/movimientos/domain/entities/movimiento.dart';
import '../features/movimientos/presentation/pages/movimiento_form_page.dart';
import '../features/movimientos/presentation/pages/movimientos_page.dart';
import '../features/resumen/presentation/pages/inicio_page.dart';
import 'home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Refresca las redirecciones cuando cambia el estado de auth.
  final authChanges = ValueNotifier<AsyncValue<AuthState>>(const AsyncLoading());
  ref
    ..listen(
      authControllerProvider,
      (_, next) => authChanges.value = next,
      fireImmediately: true,
    )
    ..onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: '/inicio',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final auth = authChanges.value;
      if (auth.isLoading && !auth.hasValue) return '/splash';
      final signedIn = auth.value?.status == AuthStatus.signedIn;
      final enLogin = state.matchedLocation == '/login';
      final enSplash = state.matchedLocation == '/splash';
      if (!signedIn) return enLogin ? null : '/login';
      if (enLogin || enSplash) return '/inicio';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/inicio', builder: (_, _) => const InicioPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/movimientos', builder: (_, _) => const MovimientosPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/metas', builder: (_, _) => const MetasPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ajustes',
              builder: (_, _) => const AjustesPage(),
              routes: [
                GoRoute(path: 'categorias', builder: (_, _) => const CategoriasPage()),
                GoRoute(path: 'cuentas', builder: (_, _) => const CuentasPage()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/movimiento/nuevo',
        pageBuilder: (_, _) => const MaterialPage(
          fullscreenDialog: true,
          child: MovimientoFormPage(),
        ),
      ),
      GoRoute(
        path: '/movimiento/:id',
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: MovimientoFormLoader(
            id: int.parse(state.pathParameters['id']!),
            inicial: state.extra as Movimiento?,
          ),
        ),
      ),
    ],
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
