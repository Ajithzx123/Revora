import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MatchBadge extends StatelessWidget {
  final int percentage;

  const MatchBadge({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isHighMatch = percentage >= 85;
    final fg = isHighMatch ? AppColors.accent : AppColors.info;
    final bg = isHighMatch ? AppColors.accentLight : AppColors.infoBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 13, color: fg),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$percentage% Match',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
