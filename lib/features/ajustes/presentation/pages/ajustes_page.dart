import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../categorias/presentation/providers/categorias_providers.dart';
import '../../../cuentas/presentation/providers/cuentas_providers.dart';
import '../providers/preferencias_controller.dart';

final _ultimoRegistroCorreoProvider = FutureProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(movimientosRepositoryProvider).ultimoRegistroPorCorreo(),
);

class AjustesPage extends ConsumerStatefulWidget {
  const AjustesPage({super.key});

  @override
  ConsumerState<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends ConsumerState<AjustesPage> {
  bool _exportando = false;

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final csv = await ref.read(movimientosRepositoryProvider).exportarCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/movimientos.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], subject: 'Movimientos'),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _toggleBio(bool v) async {
    final ok = await ref.read(preferenciasProvider.notifier).activarBiometria(v);
    if (!ok && mounted) showInfo(context, 'No se pudo activar el desbloqueo biométrico.');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value?.user;
    final prefs = ref.watch(preferenciasProvider);
    final nCategorias = ref.watch(categoriasProvider).value?.length;
    final nCuentas = ref.watch(cuentasProvider).value?.length;
    final ultimo = ref.watch(_ultimoRegistroCorreoProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            const Padding(padding: EdgeInsets.only(left: 4, bottom: 16), child: PageTitle('Ajustes')),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    foregroundImage: user?.image == null ? null : NetworkImage(user!.image!),
                    child: Text(
                      user?.initial ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Catálogos'),
            _Grupo(children: [
              _NavTile(
                icon: Icons.sell_outlined,
                titulo: 'Categorías',
                valor: nCategorias?.toString(),
                onTap: () => context.push('/ajustes/categorias'),
              ),
              _NavTile(
                icon: Icons.credit_card_outlined,
                titulo: 'Cuentas y tarjetas',
                valor: nCuentas?.toString(),
                onTap: () => context.push('/ajustes/cuentas'),
              ),
            ]),
            const SizedBox(height: 18),
            const SectionTitle('Preferencias'),
            _Grupo(children: [
              ListTile(
                minTileHeight: 60,
                title: const Text('Moneda por defecto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                trailing: DropdownButton<String>(
                  value: prefs.moneda,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'MXN', child: Text('MXN')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (v) => ref
                      .read(preferenciasProvider.notifier)
                      .actualizar((p) => p.copyWith(moneda: v)),
                ),
              ),
              SwitchListTile(
                value: prefs.avisosMovimientos,
                onChanged: (v) => ref
                    .read(preferenciasProvider.notifier)
                    .actualizar((p) => p.copyWith(avisosMovimientos: v)),
                title: const Text('Avisos de nuevos movimientos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: const Text('Notificación al registrar un cargo o abono', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              SwitchListTile(
                value: prefs.desbloqueoBiometrico,
                onChanged: _toggleBio,
                title: const Text('Desbloqueo biométrico', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: const Text('Huella o Face ID al abrir la app', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ]),
            const SizedBox(height: 18),
            const SectionTitle('Datos'),
            _Grupo(children: [
              ListTile(
                minTileHeight: 64,
                title: const Text('Registro con Claude', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  switch (ultimo) {
                    AsyncData(value: final d?) => 'Último registro vía conector: ${Fmt.fechaCorta(d)}',
                    AsyncData() => 'Sin registros por correo todavía',
                    AsyncError() => 'No se pudo consultar',
                    _ => 'Consultando…',
                  },
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                trailing: ultimo.value == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
              ),
              ListTile(
                minTileHeight: 60,
                onTap: _exportando ? null : _exportar,
                title: const Text('Exportar movimientos (CSV)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                trailing: _exportando
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, color: AppColors.primary),
              ),
            ]),
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(),
              children[i],
            ],
          ],
        ),
      );
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.titulo,
    required this.onTap,
    this.valor,
  });

  final IconData icon;
  final String titulo;
  final String? valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        minTileHeight: 60,
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (valor != null)
              Text(valor!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      );
}
