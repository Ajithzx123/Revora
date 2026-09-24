import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final String? status;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.status,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  factory StatusChip.fromStatus(String status) {
    return StatusChip(
      label: status,
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;

    Color fg = color ?? cs.onSurfaceVariant;
    Color bg = backgroundColor ?? colors.chipBg;
    IconData? ic = icon;

    if (status != null && color == null && backgroundColor == null) {
      switch (status!.toLowerCase()) {
        case 'active':
        case 'approved':
        case 'verified':
        case 'completed':
          fg = colors.statusSuccessFg;
          bg = colors.statusSuccessBg;
          ic ??= Icons.check_circle_outline;
          break;
        case 'pending':
        case 'in review':
        case 'in_review':
          fg = colors.statusWarningFg;
          bg = colors.statusWarningBg;
          ic ??= Icons.schedule;
          break;
        case 'rejected':
        case 'cancelled':
        case 'flagged':
          fg = colors.statusErrorFg;
          bg = colors.statusErrorBg;
          ic ??= Icons.cancel_outlined;
          break;
        case 'new':
        case 'quotes received':
        case 'quoted':
          fg = colors.statusInfoFg;
          bg = colors.statusInfoBg;
          ic ??= Icons.info_outline;
          break;
        default:
          fg = cs.onSurfaceVariant;
          bg = colors.chipBg;
          ic = null;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? fg.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ic != null) ...[
            Icon(ic, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
