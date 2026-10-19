import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/cuenta.dart';
import '../providers/cuentas_providers.dart';

class CuentasPage extends ConsumerWidget {
  const CuentasPage({super.key});

  void _editar(BuildContext context, [Cuenta? cuenta]) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CuentaForm(cuenta: cuenta),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(cuentasConConteoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas y tarjetas'), titleSpacing: 0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar cuenta'),
            onPressed: () => _editar(context),
          ),
        ),
      ),
      body: datos.when(
        data: (lista) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Solo se guardan los últimos 4 dígitos. El remitente sirve para reconocer de qué banco viene cada notificación.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
              ),
            ),
            if (lista.isEmpty) const EmptyState('Agrega tu primera cuenta.'),
            for (final c in lista) ...[
              _CuentaCard(c, onEditar: () => _editar(context, c.cuenta)),
              const SizedBox(height: 12),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(cuentasConConteoProvider),
        ),
      ),
    );
  }
}

class _CuentaCard extends StatelessWidget {
  const _CuentaCard(this.data, {required this.onEditar});

  final CuentaConConteo data;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final c = data.cuenta;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 36,
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                alignment: Alignment.bottomRight,
                decoration: BoxDecoration(
                  color: Color(c.color),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.ultimos4 ?? '—',
                  style: AppTheme.mono(fontSize: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(
                      c.tipo == TipoCuenta.efectivo ? c.tipo.etiqueta : '${c.tipo.etiqueta} · ${c.moneda}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar ${c.nombre}',
                onPressed: onEditar,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  fixedSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.remitente ?? 'Sin notificaciones',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              Text(
                '${data.movimientos} este mes',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CuentaForm extends ConsumerStatefulWidget {
  const _CuentaForm({this.cuenta});

  final Cuenta? cuenta;

  @override
  ConsumerState<_CuentaForm> createState() => _CuentaFormState();
}

class _CuentaFormState extends ConsumerState<_CuentaForm> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cuenta?.nombre);
  late final _ultimos4 = TextEditingController(text: widget.cuenta?.ultimos4);
  late final _remitente = TextEditingController(text: widget.cuenta?.remitente);
  late TipoCuenta _tipo = widget.cuenta?.tipo ?? TipoCuenta.debito;
  late int _color = widget.cuenta?.color ?? AppColors.cuentaColores.first.toARGB32();
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _ultimos4.dispose();
    _remitente.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    final efectivo = _tipo == TipoCuenta.efectivo;
    try {
      await ref.read(cuentasRepositoryProvider).guardar(
            Cuenta(
              id: widget.cuenta?.id ?? 0,
              nombre: _nombre.text,
              tipo: _tipo,
              moneda: widget.cuenta?.moneda ?? 'MXN',
              color: _color,
              ultimos4: efectivo || _ultimos4.text.isEmpty ? null : _ultimos4.text,
              remitente: efectivo ? null : _remitente.text,
            ),
          );
      ref
        ..invalidate(cuentasProvider)
        ..invalidate(cuentasConConteoProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final efectivo = _tipo == TipoCuenta.efectivo;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.cuenta == null ? 'Agregar cuenta' : 'Editar cuenta',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<TipoCuenta>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: TipoCuenta.debito, label: Text('Débito')),
                ButtonSegment(value: TipoCuenta.credito, label: Text('Crédito')),
                ButtonSegment(value: TipoCuenta.efectivo, label: Text('Efectivo')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            if (!efectivo) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _ultimos4,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Últimos 4 dígitos',
                  counterText: '',
                ),
                validator: (v) => (v ?? '').isEmpty || v!.length == 4
                    ? null
                    : 'Deben ser exactamente 4 dígitos',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remitente,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Remitente de notificaciones'),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final c in AppColors.cuentaColores)
                  Semantics(
                    label: 'Color',
                    selected: _color == c.toARGB32(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = c.toARGB32()),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c,
                          child: _color == c.toARGB32()
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
