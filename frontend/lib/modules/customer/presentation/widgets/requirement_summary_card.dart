import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';
import '../../domain/entities/buy_requirement.dart';

class RequirementSummaryCard extends StatefulWidget {
  final BuyRequirement requirement;
  final VoidCallback? onTap;
  final VoidCallback? onViewQuotes;
  final double? imageHeight;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const RequirementSummaryCard({
    super.key,
    required this.requirement,
    this.onTap,
    this.onViewQuotes,
    this.imageHeight = 44,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  State<RequirementSummaryCard> createState() => _RequirementSummaryCardState();
}

class _RequirementSummaryCardState extends State<RequirementSummaryCard> {
  bool _isHovered = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant RequirementSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  String _getPostedTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requirement;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? widget.onViewQuotes,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: _isHovered ? colors.cardHoverBorder : colors.cardBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark
                      ? (_isHovered ? 0.3 : 0.15)
                      : (_isHovered ? 0.08 : 0.03),
                ),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Posted time + Favorite button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPostedTimeAgo(req.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                          widget.onFavoriteChanged?.call(_isFavorite);
                        },
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _isFavorite
                                ? colors.heartLikedBg
                                : colors.heartUnlikedBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isFavorite
                                  ? colors.heartLikedFg.withValues(alpha: 0.3)
                                  : colors.heartUnlikedBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: _isFavorite
                                ? colors.heartLikedFg
                                : colors.heartUnlikedFg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // Requirement Visual Container (Compact neutral container)
                Container(
                  width: double.infinity,
                  height: widget.imageHeight ?? 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.chipBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: colors.chipBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.chipBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Seeking ${req.make} ${req.model}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

                // Name (No year) & Budget
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        '${req.make} ${req.model}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      req.budgetRange,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // Specs: Preferred City, Fuel, Min Year
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _buildSpecChip(
                      Icons.location_on_outlined,
                      req.preferredCity,
                      cs,
                      colors,
                    ),
                    _buildSpecChip(
                      Icons.local_gas_station_outlined,
                      req.fuelType,
                      cs,
                      colors,
                    ),
                    _buildSpecChip(
                      Icons.calendar_today_outlined,
                      '${req.minYear}+',
                      cs,
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action Button: Clean primary navy/slate button matching app buttons
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: widget.onViewQuotes ?? widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Have this Car? Make Offer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(
    IconData icon,
    String label,
    ColorScheme cs,
    RevoraThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: colors.chipBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
