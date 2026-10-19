import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

/// Barra inferior Material 3 (Inicio · Movimientos · Metas · Ajustes).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinos = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
    NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Movimientos'),
    NavigationDestination(icon: Icon(Icons.track_changes_outlined), selectedIcon: Icon(Icons.track_changes), label: 'Metas'),
    NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            destinations: _destinos,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
          ),
        ),
      );
}

/// FAB "Registrar movimiento" compartido por Inicio y Movimientos.
class NuevoMovimientoFab extends StatelessWidget {
  const NuevoMovimientoFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        tooltip: 'Registrar movimiento',
        onPressed: () => context.push('/movimiento/nuevo'),
        child: const Icon(Icons.add, size: 26),
      );
}
