import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';
import '../../domain/entities/sell_post.dart';

class CustomerSellCarCard extends StatefulWidget {
  final SellPost post;
  final double? imageHeight;

  const CustomerSellCarCard({
    super.key,
    required this.post,
    this.imageHeight = 110,
  });

  @override
  State<CustomerSellCarCard> createState() => _CustomerSellCarCardState();
}

class _CustomerSellCarCardState extends State<CustomerSellCarCard> {
  bool _isHovered = false;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/customer/listing/${post.id}'),
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
                  alpha: isDark
                      ? (_isHovered ? 0.3 : 0.15)
                      : (_isHovered ? 0.08 : 0.03),
                ),
                blurRadius: _isHovered ? 14 : 6,
                offset: Offset(0, _isHovered ? 5 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Tag (FOR SALE), City / Location Pill & Favorite Button
                SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.subtleBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sell_outlined,
                                  size: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'FOR SALE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post.city.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.chipBg,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                                border: Border.all(
                                  color: colors.chipBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 80,
                                    ),
                                    child: Text(
                                      post.city,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _isFavorite = !_isFavorite);
                          },
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
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
                              size: 15,
                              color: _isFavorite
                                  ? colors.heartLikedFg
                                  : colors.heartUnlikedFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Car Image Showcase (Fixed uniform height)
                SizedBox(
                  height: widget.imageHeight ?? 105,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: post.imageUrls.isNotEmpty
                        ? Image.network(
                            post.imageUrls.first,
                            width: double.infinity,
                            height: widget.imageHeight ?? 105,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildPlaceholder(colors),
                          )
                        : _buildPlaceholder(colors),
                  ),
                ),
                const SizedBox(height: 8),

                // Title (Make & Model), Variant, and Amount / Price Section (Uniform fixed height)
                SizedBox(
                  height: 42,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${post.make} ${post.model}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              post.variant.isNotEmpty
                                  ? post.variant
                                  : '${post.year} Model',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            post.formattedPrice,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Spec Details Chips: 2 balanced lines with comfortable spacing
                Column(
                  children: [
                    Row(
                      children: [
                        _buildSpecChip(
                          Icons.calendar_today_outlined,
                          '${post.year}',
                          cs,
                          colors,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecChip(
                          Icons.speed,
                          '${(post.mileage / 1000).toStringAsFixed(0)}k km',
                          cs,
                          colors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildSpecChip(
                          Icons.local_gas_station_outlined,
                          post.fuelType,
                          cs,
                          colors,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecChip(
                          Icons.tune,
                          post.transmission,
                          cs,
                          colors,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Button (Uniform height and aligned baseline)
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/customer/listing/${post.id}'),
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
                          'View Car Details',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
        decoration: BoxDecoration(
          color: colors.chipBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: colors.chipBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
    );
  }

  Widget _buildPlaceholder(RevoraThemeColors colors) {
    return Container(
      width: double.infinity,
      height: widget.imageHeight ?? 105,
      color: colors.placeholderBg,
      child: Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: 38,
          color: colors.placeholderIcon,
        ),
      ),
    );
  }
}
