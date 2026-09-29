import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final double elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.borderRadius = 12,
    this.elevation = 0,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveElevation = widget.elevation + (_isHovered && widget.onTap != null ? 3.0 : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: _isHovered && widget.onTap != null
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outline,
          width: _isHovered && widget.onTap != null ? 1.2 : 1.0,
        ),
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: effectiveElevation * 2.5,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovered) {
            if (widget.onTap != null && mounted) {
              setState(() => _isHovered = hovered);
            }
          },
          mouseCursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
