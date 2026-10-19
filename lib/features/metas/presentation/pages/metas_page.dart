import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/meta.dart';
import '../providers/metas_providers.dart';

class MetasPage extends ConsumerWidget {
  const MetasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metas = ref.watch(metasProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(metasProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: PageTitle('Metas de ahorro'),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.add,
                    tooltip: 'Nueva meta',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _NuevaMetaDialog(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...metas.when(
                data: (lista) => [
                  _Total(lista),
                  if (lista.isEmpty) const EmptyState('Crea tu primera meta con el botón +.'),
                  for (final m in lista) ...[
                    const SizedBox(height: 14),
                    _MetaCard(m),
                  ],
                ],
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [
                  ErrorRetry(error: e, onRetry: () => ref.invalidate(metasProvider)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.metas);

  final List<Meta> metas;

  @override
  Widget build(BuildContext context) {
    final ahorrado = metas.fold<int>(0, (a, m) => a + m.ahorradoCentavos);
    final objetivo = metas.fold<int>(0, (a, m) => a + m.objetivoCentavos);
    const muted = TextStyle(color: AppColors.abonoMuted, fontSize: 13);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.abono,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total ahorrado', style: muted.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(Fmt.money(ahorrado), style: AppTheme.mono(fontSize: 32, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'de ${Fmt.money(objetivo)} en ${metas.length} ${metas.length == 1 ? 'meta' : 'metas'}',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends ConsumerWidget {
  const _MetaCard(this.meta);

  final Meta meta;

  Future<void> _aportar(BuildContext context, WidgetRef ref) async {
    final monto = await showDialog<int>(
      context: context,
      builder: (_) => _MontoDialog(titulo: 'Aportar a ${meta.nombre}'),
    );
    if (monto == null) return;
    try {
      await ref.read(metasProvider.notifier).aportar(meta.id, monto);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = '${(meta.progreso * 100).round()}%';
    final sugerido = meta.aporteMensualSugerido();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (meta.fechaMeta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Meta: ${Fmt.mesMeta(meta.fechaMeta!)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                pct,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.abono,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: meta.progreso, color: AppColors.abono, height: 10),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(Fmt.money(meta.ahorradoCentavos), style: AppTheme.mono(fontSize: 13))),
              Text(
                'de ${Fmt.money(meta.objetivoCentavos)}',
                style: AppTheme.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  meta.faltanteCentavos == 0
                      ? '¡Meta cumplida!'
                      : sugerido == null
                          ? 'Faltan ${Fmt.money(meta.faltanteCentavos)}'
                          : '≈ ${Fmt.money(sugerido)} por mes para llegar',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _aportar(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: AppColors.tint,
                  foregroundColor: AppColors.primaryDark,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Aportar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo para capturar un monto; devuelve centavos.
class _MontoDialog extends StatefulWidget {
  const _MontoDialog({required this.titulo});

  final String titulo;

  @override
  State<_MontoDialog> createState() => _MontoDialogState();
}

class _MontoDialogState extends State<_MontoDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centavos = Fmt.parseCentavos(_ctrl.text);
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(prefixText: r'$ ', hintText: '0.00'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: centavos == null ? null : () => Navigator.pop(context, centavos),
          child: const Text('Aportar'),
        ),
      ],
    );
  }
}

class _NuevaMetaDialog extends ConsumerStatefulWidget {
  const _NuevaMetaDialog();

  @override
  ConsumerState<_NuevaMetaDialog> createState() => _NuevaMetaDialogState();
}

class _NuevaMetaDialogState extends ConsumerState<_NuevaMetaDialog> {
  final _nombre = TextEditingController();
  final _objetivo = TextEditingController();
  DateTime? _fecha;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final objetivo = Fmt.parseCentavos(_objetivo.text);
    if (_nombre.text.trim().isEmpty || objetivo == null) return;
    setState(() => _guardando = true);
    try {
      await ref.read(metasProvider.notifier).crear(
            nombre: _nombre.text,
            objetivoCentavos: objetivo,
            fechaMeta: _fecha,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nueva meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _objetivo,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              decoration: const InputDecoration(labelText: 'Objetivo', prefixText: r'$ '),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(_fecha == null ? 'Fecha meta (opcional)' : Fmt.mesMeta(_fecha!)),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 20),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (d != null) setState(() => _fecha = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: _guardando ? null : _guardar, child: const Text('Crear')),
        ],
      );
}
