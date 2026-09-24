import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/revora_theme_colors.dart';
import '../../../../data/mock/car_catalogue.dart';

class BrandSelectionStep extends StatefulWidget {
  final ValueChanged<String> onBrandSelected;

  const BrandSelectionStep({
    super.key,
    required this.onBrandSelected,
  });

  @override
  State<BrandSelectionStep> createState() => _BrandSelectionStepState();
}

class _BrandSelectionStepState extends State<BrandSelectionStep> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;
    final isDark = theme.brightness == Brightness.dark;

    final popularBrands = CarCatalogue.brands
        .where((b) => b.isPopular)
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final allBrands = CarCatalogue.brands
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final Map<String, List<CarBrand>> grouped = {};
    for (var b in allBrands) {
      final firstLetter = b.name[0].toUpperCase();
      grouped.putIfAbsent(firstLetter, () => []).add(b);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: colors.searchBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.searchBorder),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: cs.onSurface, fontSize: 15),
            onChanged: (val) => setState(() => _query = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search brands (e.g. Toyota, BMW, Hyundai)',
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colors.textMuted,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Popular Brands Section
        if (popularBrands.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Popular Brands',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Top Picks',
                  style: TextStyle(
                    color: cs.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: popularBrands.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final brand = popularBrands[index];
              return _buildPopularBrandCard(brand, cs, colors, isDark);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],

        // All Brands Alphabetical Section
        Text(
          'All Brands (A - Z)',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (sortedKeys.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No brand found for "$_query"',
                style: TextStyle(color: colors.textMuted, fontSize: 14),
              ),
            ),
          )
        else
          ...sortedKeys.map((letter) {
            final list = grouped[letter]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: colors.cardBorder),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 0.8,
                      color: colors.divider,
                    ),
                    itemBuilder: (context, idx) {
                      final b = list[idx];
                      return InkWell(
                        onTap: () => widget.onBrandSelected(b.name),
                        borderRadius: idx == 0 && list.length == 1
                            ? BorderRadius.circular(AppSpacing.radiusMd)
                            : idx == 0
                                ? const BorderRadius.vertical(top: Radius.circular(12))
                                : idx == list.length - 1
                                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                    : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              _buildBrandInitialBadge(b.name, cs, colors),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: cs.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildPopularBrandCard(
    CarBrand brand,
    ColorScheme cs,
    RevoraThemeColors colors,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onBrandSelected(brand.name),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        splashColor: cs.secondary.withValues(alpha: 0.15),
        highlightColor: cs.secondary.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: brand.icon != null
                      ? Icon(
                          brand.icon,
                          color: cs.onSurface,
                          size: 26,
                        )
                      : Text(
                          brand.name.isNotEmpty ? brand.name[0] : '?',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                brand.name,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandInitialBadge(
    String name,
    ColorScheme cs,
    RevoraThemeColors colors,
  ) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '';

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.chipBorder, width: 0.8),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
