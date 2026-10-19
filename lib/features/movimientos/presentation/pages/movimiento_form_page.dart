import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../ajustes/presentation/providers/preferencias_controller.dart';
import '../../../categorias/presentation/providers/categorias_providers.dart';
import '../../../cuentas/domain/entities/cuenta.dart';
import '../../../cuentas/presentation/providers/cuentas_providers.dart';
import '../../domain/entities/movimiento.dart';
import '../providers/movimientos_providers.dart';

/// Carga el movimiento si se llega por deep link sin `extra`.
class MovimientoFormLoader extends ConsumerWidget {
  const MovimientoFormLoader({super.key, required this.id, this.inicial});

  final int id;
  final Movimiento? inicial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (inicial != null) return MovimientoFormPage(original: inicial);
    return ref.watch(movimientoPorIdProvider(id)).when(
          data: (m) => MovimientoFormPage(original: m),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(movimientoPorIdProvider(id)),
            ),
          ),
        );
  }
}

class MovimientoFormPage extends ConsumerStatefulWidget {
  const MovimientoFormPage({super.key, this.original});

  final Movimiento? original;

  @override
  ConsumerState<MovimientoFormPage> createState() => _MovimientoFormPageState();
}

class _MovimientoFormPageState extends ConsumerState<MovimientoFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _concepto;
  late final TextEditingController _notas;
  late TipoMovimiento _tipo;
  late DateTime _fecha;
  String? _categoria;
  int? _cuentaId;
  bool _guardando = false;

  Movimiento? get _o => widget.original;

  @override
  void initState() {
    super.initState();
    final o = _o;
    _tipo = o?.tipo ?? TipoMovimiento.cargo;
    _fecha = o?.fecha ?? DateTime.now();
    _categoria = o?.categoria;
    _cuentaId = o?.cuentaId;
    _monto = TextEditingController(
      text: o == null ? '' : (o.montoCentavos / 100).toStringAsFixed(2),
    );
    _concepto = TextEditingController(text: o?.concepto);
    _notas = TextEditingController(text: o?.notas);
  }

  @override
  void dispose() {
    _monto.dispose();
    _concepto.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() => _fecha = DateTime(d.year, d.month, d.day, _fecha.hour, _fecha.minute));
  }

  /// Dígitos de la cuenta elegida (null en efectivo). Si no hay cuenta del
  /// catálogo, conserva los dígitos originales (p. ej. registrados por correo).
  String? _ultimos4De(int? cuentaId) {
    if (cuentaId == null) return _o?.cuentaId == null ? _o?.cuenta : null;
    final cuentas = ref.read(cuentasProvider).value ?? const [];
    for (final c in cuentas) {
      if (c.id == cuentaId) return c.ultimos4;
    }
    return null;
  }

  /// Cuenta seleccionada: la FK, o la que coincide por dígitos (datos previos).
  int? _cuentaSeleccionada(List<Cuenta> cuentas) {
    if (_cuentaId != null) return _cuentaId;
    final digitos = _o?.cuenta;
    if (digitos == null) return null;
    for (final c in cuentas) {
      if (c.ultimos4 == digitos) return c.id;
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_categoria == null) {
      showInfo(context, 'Elige una categoría.');
      return;
    }
    setState(() => _guardando = true);
    final input = MovimientoInput(
      tipo: _tipo,
      montoCentavos: Fmt.parseCentavos(_monto.text)!,
      fecha: _fecha,
      concepto: _concepto.text,
      categoria: _categoria!,
      moneda: _o?.moneda ?? ref.read(preferenciasProvider).moneda,
      cuentaId: _cuentaId,
      cuenta: _ultimos4De(_cuentaId),
      notas: _notas.text,
    );
    try {
      final repo = ref.read(movimientosRepositoryProvider);
      if (_o == null) {
        await repo.crear(input);
      } else {
        await repo.actualizar(_o!, input);
      }
      invalidarDependientesDeMovimientos(ref);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCargo = _tipo == TipoMovimiento.cargo;
    final color = esCargo ? AppColors.cargo : AppColors.abono;
    final tipoBloqueado = _o?.tipoBloqueado ?? false;
    final categorias = ref.watch(categoriasProvider);
    final cuentas = ref.watch(cuentasProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(_o == null ? 'Nuevo movimiento' : 'Editar movimiento'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Guardar movimiento'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SegmentedButton<TipoMovimiento>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: TipoMovimiento.cargo, label: Text('Cargo')),
                ButtonSegment(value: TipoMovimiento.abono, label: Text('Abono')),
              ],
              selected: {_tipo},
              onSelectionChanged: tipoBloqueado
                  ? null
                  : (s) => setState(() {
                        _tipo = s.first;
                        _categoria = null;
                      }),
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? color : AppColors.surface,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Monto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${esCargo ? '−' : '+'}\$',
                  style: AppTheme.mono(fontSize: 40, color: color),
                ),
                const SizedBox(width: 6),
                IntrinsicWidth(
                  child: TextFormField(
                    controller: _monto,
                    autofocus: _o == null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: AppTheme.mono(fontSize: 40, color: color),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: AppTheme.mono(fontSize: 40, color: AppColors.border),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) =>
                        Fmt.parseCentavos(v ?? '') == null ? 'Monto inválido' : null,
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                _o?.moneda ?? ref.watch(preferenciasProvider).moneda,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            _Label('Concepto', htmlFor: TextFormField(
              controller: _concepto,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(counterText: ''),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe un concepto' : null,
            )),
            const SizedBox(height: 20),
            const Text('Categoría', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            categorias.when(
              data: (lista) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Primero las del tipo elegido; el resto sigue disponible
                  // (p. ej. "Transferencia" puede ser cargo o abono).
                  for (final c in [
                    ...lista.where((c) => c.esIngreso != esCargo),
                    ...lista.where((c) => c.esIngreso == esCargo),
                  ])
                    ChoiceChip(
                      label: Text(c.nombre),
                      selected: _categoria == c.nombre,
                      onSelected: (_) => setState(() => _categoria = c.nombre),
                    ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => ErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(categoriasProvider),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Label('Fecha', htmlFor: OutlinedButton(
                    onPressed: _elegirFecha,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    child: Text(DateFormat('d MMM y', 'es_MX').format(_fecha)),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Valor = id de la cuenta: las de efectivo no tienen dígitos.
                  // La key recrea el campo cuando llega el catálogo.
                  child: _Label('Cuenta', htmlFor: DropdownButtonFormField<int?>(
                    key: ValueKey(cuentas.length),
                    initialValue: _cuentaSeleccionada(cuentas),
                    isExpanded: true,
                    onChanged: tipoBloqueado ? null : (v) => setState(() => _cuentaId = v),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin cuenta')),
                      for (final c in cuentas)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.etiquetaCorta, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Label(
              'Notas',
              opcional: true,
              htmlFor: TextFormField(
                controller: _notas,
                maxLines: 2,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Ej. comida con el equipo',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al editar un movimiento registrado desde un correo, el origen y el ID del correo no se pueden cambiar.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.htmlFor, this.opcional = false});

  final String text;
  final Widget htmlFor;
  final bool opcional;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: text,
              children: [
                if (opcional)
                  const TextSpan(
                    text: ' (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textMuted),
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          htmlFor,
        ],
      );
}
