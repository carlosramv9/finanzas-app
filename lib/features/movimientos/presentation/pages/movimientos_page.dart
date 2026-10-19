import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/home_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../categorias/presentation/providers/categorias_providers.dart';
import '../../domain/entities/movimiento.dart';
import '../providers/movimientos_providers.dart';
import '../widgets/movimiento_tile.dart';

class MovimientosPage extends ConsumerStatefulWidget {
  const MovimientosPage({super.key});

  @override
  ConsumerState<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends ConsumerState<MovimientosPage> {
  final _scroll = ScrollController();
  late final TextEditingController _buscar;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _buscar = TextEditingController(text: ref.read(movimientosFiltroProvider).texto);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _buscar.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(movimientosListProvider.notifier).cargarMas().catchError((Object e) {
        if (mounted) showError(context, e);
      });
    }
  }

  /// Una consulta por pausa al escribir, no por tecla.
  void _onBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(movimientosFiltroProvider.notifier).texto(v),
    );
  }

  Future<void> _elegirCategoria() async {
    final actual = ref.read(movimientosFiltroProvider).categoria;
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _CategoriaSheet(actual: actual),
    );
    if (elegida == null) return;
    ref.read(movimientosFiltroProvider.notifier).categoria(elegida.isEmpty ? null : elegida);
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(movimientosFiltroProvider);
    final lista = ref.watch(movimientosListProvider);

    return Scaffold(
      floatingActionButton: const NuevoMovimientoFab(),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: PageTitle('Movimientos'),
                  ),
                  TextField(
                    controller: _buscar,
                    onChanged: _onBuscar,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por concepto',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (t, label) in const [
                        (null, 'Todos'),
                        (TipoMovimiento.cargo, 'Cargos'),
                        (TipoMovimiento.abono, 'Abonos'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: filtro.tipo == t,
                          onSelected: (_) =>
                              ref.read(movimientosFiltroProvider.notifier).tipo(t),
                        ),
                      InputChip(
                        label: Text(filtro.categoria ?? 'Categoría ▾'),
                        selected: filtro.categoria != null,
                        onPressed: _elegirCategoria,
                        onDeleted: filtro.categoria == null
                            ? null
                            : () => ref
                                .read(movimientosFiltroProvider.notifier)
                                .categoria(null),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: lista.when(
                skipLoadingOnReload: true,
                data: (s) => RefreshIndicator(
                  onRefresh: () => ref.refresh(movimientosListProvider.future),
                  child: s.items.isEmpty
                      ? ListView(children: const [EmptyState('No hay movimientos con estos filtros.')])
                      : _ListaAgrupada(
                          controller: _scroll,
                          items: s.items,
                          cargandoMas: s.cargandoMas,
                        ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorRetry(
                  error: e,
                  onRetry: () => ref.invalidate(movimientosListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _Fila {}

class _FilaDia extends _Fila {
  _FilaDia(this.titulo, this.cantidad);
  final String titulo;
  final int cantidad;
}

class _FilaMov extends _Fila {
  _FilaMov(this.m);
  final Movimiento m;
}

class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({
    required this.controller,
    required this.items,
    required this.cargandoMas,
  });

  final ScrollController controller;
  final List<Movimiento> items;
  final bool cargandoMas;

  /// Agrupa en memoria la página ya descargada (O(n), sin consultas extra).
  List<_Fila> _filas() {
    final filas = <_Fila>[];
    var idxDia = -1;
    DateTime? clave;
    for (final m in items) {
      final d = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      if (d != clave) {
        clave = d;
        idxDia = filas.length;
        filas.add(_FilaDia(Fmt.encabezadoDia(m.fecha), 0));
      }
      filas.add(_FilaMov(m));
      final dia = filas[idxDia] as _FilaDia;
      filas[idxDia] = _FilaDia(dia.titulo, dia.cantidad + 1);
    }
    return filas;
  }

  @override
  Widget build(BuildContext context) {
    final filas = _filas();
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
      itemCount: filas.length + (cargandoMas ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == filas.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return switch (filas[i]) {
          _FilaDia(:final titulo, :final cantidad) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '$cantidad ${cantidad == 1 ? 'movimiento' : 'movimientos'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          _FilaMov(:final m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MovimientoTile(
                movimiento: m,
                detalle: [
                  m.categoria,
                  if (m.cuenta != null) '••${m.cuenta}',
                  m.origen.etiqueta,
                ].join(' · '),
              ),
            ),
        };
      },
    );
  }
}

class _CategoriaSheet extends ConsumerWidget {
  const _CategoriaSheet({required this.actual});

  final String? actual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriasProvider);
    return SafeArea(
      child: cats.when(
        data: (lista) => ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Todas las categorías'),
              trailing: actual == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final c in lista)
              ListTile(
                title: Text(c.nombre),
                subtitle: c.esIngreso ? const Text('Ingreso') : null,
                trailing: actual == c.nombre ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, c.nombre),
              ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(categoriasProvider)),
      ),
    );
  }
}
