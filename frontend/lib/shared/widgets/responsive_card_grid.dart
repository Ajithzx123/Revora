import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Lays cards out in 1, 2 or 3 columns depending on the width it is given, so a
/// phone gets one comfortable column and a desktop does not get stretched rows.
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const ResponsiveCardGrid({super.key, required this.children, this.gap = AppSpacing.md});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
      final itemWidth = (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
      );
    });
  }
}
