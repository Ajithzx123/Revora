import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Photo-first card used for cars, requirements and quotes.
/// Photo on top with a status pill and a save button, then title, price,
/// spec chips and the call-to-action(s). It fills a bounded height (horizontal
/// carousels) by pinning the actions to the bottom, and sizes to its content
/// in vertical lists.
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
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant CarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) _liked = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final raised = _hovered && tappable;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, raised ? -2 : 0, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: raised ? 0.10 : 0.04),
                  blurRadius: raised ? 22 : 10,
                  offset: Offset(0, raised ? 10 : 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (context, constraints) {
              final bounded = constraints.hasBoundedHeight;
              final body = _body(context, bounded);
              return Column(
                mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _photo(),
                  if (bounded) Expanded(child: body) else body,
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    final height = widget.imageHeight ?? 150;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.imageUrl.isEmpty
              ? _placeholder()
              : Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _placeholder(),
                  errorBuilder: (_, _, _) => _placeholder(),
                ),
          // Soft scrim so the pill and heart stay legible on bright photos.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x66000000), Color(0x00000000)],
              ),
            ),
          ),
          if (widget.badgeText != null)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.badgeBgColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  widget.badgeText!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.badgeTextColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          if (widget.showFavorite)
            Positioned(
              right: 8,
              top: 8,
              child: Semantics(
                button: true,
                label: _liked ? 'Remove from saved' : 'Save',
                child: Material(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() => _liked = !_liked);
                      widget.onFavoriteChanged?.call(_liked);
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: _liked ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, bool bounded) {
    final hasActions = widget.primaryAction != null || widget.secondaryAction != null;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 16),
          ),
          if (widget.subtitle != null || widget.location != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.location ?? widget.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(widget.priceText, maxLines: 1, style: AppTextStyles.price),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(widget.priceLabel.toUpperCase(), style: AppTextStyles.overline.copyWith(fontSize: 10)),
            ],
          ),
          if (widget.specs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final s in widget.specs) _SpecPill(item: s)],
            ),
          ],
          if (hasActions) ...[
            // Pin the buttons to the bottom when the card has a fixed height (carousels);
            // in a list the card sizes to its content, where a Spacer would be an error.
            if (bounded) const Spacer() else const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.secondaryAction != null) ...[
                  Expanded(child: _compact(context, widget.secondaryAction!)),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (widget.primaryAction != null)
                  Expanded(
                    flex: widget.secondaryAction != null ? 2 : 1,
                    child: _compact(context, widget.primaryAction!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Buttons inside a card are a little shorter than full-width page buttons.
  Widget _compact(BuildContext context, Widget button) {
    final theme = Theme.of(context);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge.copyWith(fontSize: 14)),
    );
    return Theme(
      data: theme.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: (theme.elevatedButtonTheme.style ?? const ButtonStyle()).merge(style),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: (theme.filledButtonTheme.style ?? const ButtonStyle()).merge(style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: (theme.outlinedButtonTheme.style ?? const ButtonStyle()).merge(style),
        ),
      ),
      child: SizedBox(width: double.infinity, child: button),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primarySubtle,
        alignment: Alignment.center,
        child: const Icon(Icons.directions_car_filled_outlined, size: 44, color: AppColors.textMuted),
      );
}

class _SpecPill extends StatelessWidget {
  final CarSpecItem item;
  const _SpecPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 14, color: item.color ?? AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            item.label,
            style: AppTextStyles.labelMedium.copyWith(fontSize: 12.5, color: color),
          ),
        ],
      ),
    );
  }
}

class CarSpecItem {
  final String label;
  final IconData? icon;
  final Color? color;

  const CarSpecItem({
    required this.label,
    this.icon,
    this.color,
  });
}
