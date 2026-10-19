import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/movimiento.dart';

/// Fila de movimiento. `compact` = variante de "Recientes" con avatar.
class MovimientoTile extends StatelessWidget {
  const MovimientoTile({
    super.key,
    required this.movimiento,
    required this.detalle,
    this.compact = false,
  });

  final Movimiento movimiento;
  final String detalle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final content = Row(
      children: [
        if (compact) ...[
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.tint,
            child: Text(
              m.concepto.isEmpty ? '?' : m.concepto.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.concepto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        MontoText(m.montoCentavos, esAbono: m.tipo.esAbono),
      ],
    );

    return Material(
      color: compact ? Colors.transparent : AppColors.surface,
      borderRadius: compact ? null : BorderRadius.circular(14),
      child: InkWell(
        borderRadius: compact ? null : BorderRadius.circular(14),
        onTap: () => context.push('/movimiento/${m.id}', extra: m),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 60 : 64),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14, vertical: 8),
            child: content,
          ),
        ),
      ),
    );
  }
}
