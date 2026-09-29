import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/revora_theme_colors.dart';
import '../../../../data/mock/car_catalogue.dart';

class VariantSelectionStep extends StatelessWidget {
  final String brand;
  final String model;
  final ValueChanged<String> onVariantSelected;

  const VariantSelectionStep({
    super.key,
    required this.brand,
    required this.model,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;
    final isDark = theme.brightness == Brightness.dark;

    final models = CarCatalogue.getModelsForBrand(brand);
    final modelInfo = models.firstWhere(
      (m) => m.name.toLowerCase() == model.toLowerCase(),
      orElse: () => CarModelInfo(
        name: model,
        category: 'Vehicle',
        startingPrice: '₹10.00 L',
        variants: ['Base Variant', 'Mid Variant', 'Top Variant'],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Select $model Trim / Variant',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accentSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '${modelInfo.variants.length} Available',
                style: TextStyle(
                  color: cs.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick the exact trim or variant configuration you want quotes for',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: modelInfo.variants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final variantName = modelInfo.variants[index];
            final isTop = index == modelInfo.variants.length - 1;
            final isPopular = index == 1 || index == 2;

            final borderColor = isTop
                ? cs.secondary.withValues(alpha: 0.4)
                : colors.cardBorder;

            final iconBoxBg = isTop
                ? colors.accentSubtle
                : colors.iconBg;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onVariantSelected(variantName),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                splashColor: cs.secondary.withValues(alpha: 0.12),
                highlightColor: cs.secondary.withValues(alpha: 0.06),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBoxBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isTop ? Icons.star_rounded : Icons.tune_rounded,
                          color: isTop ? cs.secondary : cs.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    variantName,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isTop) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TOP SPEC',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.statusInfoBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'POPULAR',
                                      style: TextStyle(
                                        color: colors.statusInfoFg,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Standard key features & engine options available',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_outline,
                        color: cs.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
