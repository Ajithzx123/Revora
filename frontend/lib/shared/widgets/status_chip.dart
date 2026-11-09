import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  factory StatusChip.fromStatus(String status) {
    Color fg;
    Color bg;
    IconData? ic;

    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
      case 'completed':
        fg = AppColors.success;
        bg = AppColors.successBg;
        ic = Icons.check_circle_outline;
        break;
      case 'pending':
      case 'in review':
      case 'in_review':
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        ic = Icons.schedule;
        break;
      case 'rejected':
      case 'cancelled':
      case 'flagged':
        fg = AppColors.error;
        bg = AppColors.errorBg;
        ic = Icons.cancel_outlined;
        break;
      case 'new':
      case 'quotes received':
      case 'quoted':
        fg = AppColors.info;
        bg = AppColors.infoBg;
        ic = Icons.info_outline;
        break;
      default:
        fg = AppColors.textSecondary;
        bg = AppColors.borderLight;
        ic = null;
    }

    return StatusChip(label: status, color: fg, backgroundColor: bg, icon: ic);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFg = color ?? AppColors.textSecondary;
    final effectiveBg = backgroundColor ?? AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveFg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: effectiveFg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
