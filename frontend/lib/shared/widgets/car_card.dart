import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/revora_theme_colors.dart';

/// Universal car display card matching modern aesthetic:
/// - Pill badge (e.g., "Sale", "96% Match", "Active")
/// - Heart/Favorite button (interactive or custom action)
/// - Centered hero car image
/// - Title & Location / Subtitle
/// - Right-aligned "Price" header & Price tag
/// - Spec chips / pills for extra details (Year, Km, Fuel, Rating, etc.)
/// - Customizable action button(s) at bottom
class CarCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? location;
  final String priceText;
  final String priceLabel;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final bool showFavorite;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  final List<CarSpecItem> specs;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onTap;
  final double? imageHeight;

  const CarCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.location,
    required this.priceText,
    this.priceLabel = 'Price',
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    this.showFavorite = true,
    this.isFavorite = false,
    this.onFavoriteChanged,
    this.specs = const [],
    this.primaryAction,
    this.secondaryAction,
    this.onTap,
    this.imageHeight,
  });

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  late bool _liked;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant CarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _liked = widget.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
                blurRadius: _isHovered ? 14 : 6,
                offset: Offset(0, _isHovered ? 5 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Badges Row: Pill Badge (e.g. Sale, Match %) + Favorite Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.badgeText != null &&
                        widget.badgeText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.badgeBgColor ?? colors.subtleBg,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: widget.badgeTextColor ?? cs.onSurface,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (widget.showFavorite)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _liked = !_liked);
                            widget.onFavoriteChanged?.call(_liked);
                          },
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _liked
                                  ? colors.heartLikedBg
                                  : colors.heartUnlikedBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _liked
                                    ? colors.heartLikedFg.withValues(alpha: 0.3)
                                    : colors.heartUnlikedBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              size: 17,
                              color: _liked
                                  ? colors.heartLikedFg
                                  : colors.heartUnlikedFg,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),

                const SizedBox(height: 6),

                // 2. Centered Car Hero Showcase
                if (widget.imageHeight != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              width: double.infinity,
                              height: widget.imageHeight,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildImagePlaceholder(
                                height: widget.imageHeight,
                                colors: colors,
                              ),
                            )
                          : _buildImagePlaceholder(
                              height: widget.imageHeight,
                              colors: colors,
                            ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildImagePlaceholder(colors: colors),
                              )
                            : _buildImagePlaceholder(colors: colors),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),

                // 3. Title + Location / Subtitle + Price Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (widget.location != null &&
                              widget.location!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    widget.location!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.priceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.priceText,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 4. Spec Details Chips
                if (widget.specs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.specs
                        .map((s) => _buildSpecPill(s, cs, colors))
                        .toList(),
                  ),
                ],

                // 5. Actions row if provided
                if (widget.primaryAction != null ||
                    widget.secondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (widget.secondaryAction != null)
                        Expanded(child: widget.secondaryAction!),
                      if (widget.secondaryAction != null &&
                          widget.primaryAction != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (widget.primaryAction != null)
                        Expanded(child: widget.primaryAction!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecPill(
    CarSpecItem item,
    ColorScheme cs,
    RevoraThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: colors.chipBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 11, color: item.color ?? cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: item.color ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder({
    double? height,
    required RevoraThemeColors colors,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      color: colors.placeholderBg,
      child: Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: height != null ? (height * 0.45).clamp(24.0, 56.0) : 56,
          color: colors.placeholderIcon,
        ),
      ),
    );
  }
}

class CarSpecItem {
  final String label;
  final IconData? icon;
  final Color? color;

  const CarSpecItem({required this.label, this.icon, this.color});
}
