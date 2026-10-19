import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/home_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../movimientos/presentation/providers/movimientos_providers.dart';
import '../../../movimientos/presentation/widgets/movimiento_tile.dart';
import '../../domain/entities/resumen_periodo.dart';
import '../providers/resumen_providers.dart';

class InicioPage extends ConsumerWidget {
  const InicioPage({super.key});

  static const categoriaPorClasificar = 'Otros';

  Future<void> _elegirMes(BuildContext context, WidgetRef ref) async {
    final actual = ref.read(mesSeleccionadoProvider);
    final elegido = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Elige un día del mes a consultar',
    );
    if (elegido != null) ref.read(mesSeleccionadoProvider.notifier).elegir(elegido);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSeleccionadoProvider);
    final resumen = ref.watch(resumenMesProvider);
    final recientes = ref.watch(recientesProvider);

    return Scaffold(
      floatingActionButton: const NuevoMovimientoFab(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(resumenMesProvider)
              ..invalidate(recientesProvider);
            await ref.read(resumenMesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hola de nuevo',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          PageTitle(Fmt.mesAnio(mes)),
                        ],
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.calendar_month_outlined,
                    tooltip: 'Cambiar mes',
                    onPressed: () => _elegirMes(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              resumen.when(
                data: (r) => _ResumenSecciones(r),
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorRetry(
                  error: e,
                  onRetry: () => ref.invalidate(resumenMesProvider),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recientes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/movimientos'),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    recientes.when(
                      data: (items) => items.isEmpty
                          ? const EmptyState('Aún no hay movimientos.')
                          : Column(
                              children: [
                                for (final m in items) ...[
                                  const Divider(),
                                  MovimientoTile(
                                    movimiento: m,
                                    compact: true,
                                    detalle: '${Fmt.fechaCorta(m.fecha)} · ${m.categoria}',
                                  ),
                                ],
                              ],
                            ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => ErrorRetry(
                        error: e,
                        onRetry: () => ref.invalidate(recientesProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenSecciones extends ConsumerWidget {
  const _ResumenSecciones(this.r);

  final ResumenPeriodo r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxGasto = r.gastoPorCategoria.isEmpty
        ? 1
        : r.gastoPorCategoria.first.totalCentavos.clamp(1, 1 << 62);
    final top = r.gastoPorCategoria.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Balance del mes',
                style: TextStyle(
                  color: AppColors.onPrimaryMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.balanceCentavos < 0 ? '−' : ''}${Fmt.money(r.balanceCentavos)}',
                style: AppTheme.mono(fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _Mini('Abonos', r.abonosCentavos, esAbono: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _Mini('Cargos', r.cargosCentavos, esAbono: false)),
                ],
              ),
            ],
          ),
        ),
        if (r.porClasificar > 0) ...[
          const SizedBox(height: 16),
          Material(
            color: AppColors.warningBg,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.warningBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ref
                    .read(movimientosFiltroProvider.notifier)
                    .soloCategoria(InicioPage.categoriaPorClasificar);
                context.go('/movimientos');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.warningText, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${r.porClasificar} ${r.porClasificar == 1 ? 'movimiento' : 'movimientos'} sin categoría',
                        style: const TextStyle(
                          color: AppColors.warningText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      'Revisar',
                      style: TextStyle(
                        color: AppColors.warningText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'En qué se fue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if (top.isEmpty) const EmptyState('Sin cargos este mes.'),
              for (final c in top) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.nombre,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      Fmt.money(c.totalCentavos),
                      style: AppTheme.mono(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(value: c.totalCentavos / maxGasto),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.centavos, {required this.esAbono});

  final String label;
  final int centavos;
  final bool esAbono;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MontoText(centavos, esAbono: esAbono, fontSize: 15),
            ),
          ],
        ),
      );
}
