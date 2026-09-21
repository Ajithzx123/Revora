import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../domain/entities/buy_requirement.dart';

class RequirementSummaryCard extends StatelessWidget {
  final BuyRequirement requirement;
  final VoidCallback? onTap;
  final VoidCallback? onViewQuotes;
  final double? imageHeight;

  const RequirementSummaryCard({
    super.key,
    required this.requirement,
    this.onTap,
    this.onViewQuotes,
    this.imageHeight,
  });

  static String _resolveCarImage(String make, String model) {
    final key = '$make $model'.toLowerCase();
    if (key.contains('creta')) {
      return 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=500';
    } else if (key.contains('nexon')) {
      return 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=500';
    } else if (key.contains('city')) {
      return 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=500';
    } else if (key.contains('swift')) {
      return 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=500';
    }
    return 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=500';
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeTextColor = Colors.white;
    switch (requirement.status.toLowerCase()) {
      case 'active':
        badgeColor = AppColors.success;
        break;
      case 'completed':
        badgeColor = AppColors.primary;
        break;
      default:
        badgeColor = AppColors.textSecondary;
    }

    return CarCard(
      onTap: onTap,
      imageHeight: imageHeight,
      imageUrl: _resolveCarImage(requirement.make, requirement.model),
      title: requirement.title,
      location: '${requirement.preferredCity} • Looking for ${requirement.minYear}+',
      priceLabel: 'Budget Range',
      priceText: requirement.budgetRange,
      badgeText: requirement.status.toUpperCase(),
      badgeBgColor: badgeColor,
      badgeTextColor: badgeTextColor,
      specs: [
        CarSpecItem(
          icon: Icons.local_gas_station_outlined,
          label: requirement.fuelType,
        ),
        CarSpecItem(
          icon: Icons.tune,
          label: requirement.transmission,
        ),
        CarSpecItem(
          icon: Icons.location_on_outlined,
          label: requirement.preferredCity,
        ),
        CarSpecItem(
          icon: Icons.local_offer_outlined,
          label: '${requirement.quotesReceived} Quotes',
          color: AppColors.success,
        ),
      ],
      primaryAction: ElevatedButton(
        onPressed: onViewQuotes,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
        child: Text(
          requirement.quotesReceived > 0
              ? 'View ${requirement.quotesReceived} Quotes'
              : 'View Requirement',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
