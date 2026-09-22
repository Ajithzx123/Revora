import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final searchBg = isDark ? const Color(0xFF24272C) : Colors.white;
    final searchBorder = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final hintColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final sectionHeaderColor = isDark ? Colors.grey[400] : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: searchBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: searchBorder),
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
            style: TextStyle(color: textColor, fontSize: 15),
            onChanged: (val) => setState(() => _query = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search brands (e.g. Toyota, BMW, Hyundai)',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: hintColor,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: hintColor, size: 18),
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
                  color: sectionHeaderColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Top Picks',
                  style: TextStyle(
                    color: AppColors.accent,
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
              return _buildPopularBrandCard(brand, isDark);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],

        // All Brands Alphabetical Section
        Text(
          'All Brands (A - Z)',
          style: TextStyle(
            color: sectionHeaderColor,
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
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
            ),
          )
        else
          ...sortedKeys.map((letter) {
            final list = grouped[letter]!;
            final containerBg = isDark ? const Color(0xFF1E2126) : Colors.white;
            final containerBorder = isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.border;
            final dividerColor = isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.borderLight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: containerBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: containerBorder),
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
                      color: dividerColor,
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
                              _buildBrandInitialBadge(b.name, isDark),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark ? Colors.grey[600] : AppColors.icon,
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

  Widget _buildPopularBrandCard(CarBrand brand, bool isDark) {
    final cardBg = isDark ? const Color(0xFF22262C) : Colors.white;
    final iconBoxBg = isDark ? const Color(0xFF2D323A) : const Color(0xFFF1F5F9);
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final iconColor = isDark ? Colors.white : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onBrandSelected(brand.name),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        splashColor: AppColors.accent.withValues(alpha: 0.15),
        highlightColor: AppColors.accent.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cardBorder),
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
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: brand.icon != null
                      ? Icon(
                          brand.icon,
                          color: iconColor,
                          size: 26,
                        )
                      : Text(
                          brand.name.isNotEmpty ? brand.name[0] : '?',
                          style: TextStyle(
                            color: iconColor,
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
                  color: textColor,
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

  Widget _buildBrandInitialBadge(String name, bool isDark) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '';
    final badgeBg = isDark ? const Color(0xFF2B3038) : const Color(0xFFE2E8F0);
    final badgeTextColor = isDark ? Colors.white70 : AppColors.primary;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: badgeTextColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
