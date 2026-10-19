import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../movimientos/presentation/providers/movimientos_providers.dart';
import '../../domain/entities/categoria.dart';
import '../providers/categorias_providers.dart';

class CategoriasPage extends ConsumerWidget {
  const CategoriasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(categoriasConTotalesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categorías'),
          titleSpacing: 0,
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.divider,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Gastos'), Tab(text: 'Ingresos')],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Builder(
              builder: (context) => FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _NuevaCategoriaDialog(
                    ingreso: DefaultTabController.of(context).index == 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: datos.when(
          data: (lista) => TabBarView(
            children: [
              _Lista(lista.where((c) => !c.categoria.esIngreso).toList()),
              _Lista(lista.where((c) => c.categoria.esIngreso).toList()),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            error: e,
            onRetry: () => ref.invalidate(categoriasConTotalesProvider),
          ),
        ),
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista(this.items);

  final List<CategoriaConTotal> items;

  String _detalle(CategoriaConTotal c) {
    final n = c.movimientos;
    final movs = n == 0
        ? 'Sin movimientos este mes'
        : '$n ${n == 1 ? 'movimiento' : 'movimientos'}';
    if (c.categoria.esIngreso || n == 0) return movs;
    final p = c.categoria.presupuestoCentavos;
    return '$movs · ${p == null ? 'sin presupuesto' : 'presupuesto ${Fmt.money(p)}'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const EmptyState('No hay categorías.');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = items[i];
        final excedido = c.categoria.presupuestoCentavos != null &&
            c.totalCentavos > c.categoria.presupuestoCentavos!;
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            minTileHeight: 68,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () {
              ref.read(movimientosFiltroProvider.notifier).soloCategoria(c.categoria.nombre);
              context.go('/movimientos');
            },
            title: Text(c.categoria.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            subtitle: Text(_detalle(c), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Fmt.money(c.totalCentavos),
                  style: AppTheme.mono(
                    color: excedido ? AppColors.cargo : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NuevaCategoriaDialog extends ConsumerStatefulWidget {
  const _NuevaCategoriaDialog({required this.ingreso});

  final bool ingreso;

  @override
  ConsumerState<_NuevaCategoriaDialog> createState() => _NuevaCategoriaDialogState();
}

class _NuevaCategoriaDialogState extends ConsumerState<_NuevaCategoriaDialog> {
  final _nombre = TextEditingController();
  final _presupuesto = TextEditingController();
  late bool _ingreso = widget.ingreso;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _presupuesto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      await ref.read(categoriasRepositoryProvider).crear(
            Categoria(
              nombre: _nombre.text,
              esIngreso: _ingreso,
              presupuestoCentavos: _ingreso ? null : Fmt.parseCentavos(_presupuesto.text),
            ),
          );
      ref
        ..invalidate(categoriasProvider)
        ..invalidate(categoriasConTotalesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre', counterText: ''),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ingreso,
              onChanged: (v) => setState(() => _ingreso = v),
              title: const Text('Es de ingreso'),
            ),
            if (!_ingreso)
              TextField(
                controller: _presupuesto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  labelText: 'Presupuesto mensual (opcional)',
                  prefixText: r'$ ',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: _guardando ? null : _guardar, child: const Text('Crear')),
        ],
      );
}
