import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final Color badgeColor = requirement.isOpen
        ? AppColors.success
        : requirement.isPaused
            ? AppColors.warning
            : AppColors.textSecondary;
    const badgeTextColor = Colors.white;

    return CarCard(
      onTap: onTap,
      imageHeight: imageHeight,
      imageUrl: _resolveCarImage(requirement.make, requirement.model),
      title: requirement.title,
      location: '${requirement.preferredCity} · ${requirement.urgencyLabel}',
      priceLabel: 'Budget',
      priceText: requirement.budgetRange,
      badgeText: requirement.statusLabel.toUpperCase(),
      badgeBgColor: badgeColor,
      badgeTextColor: badgeTextColor,
      specs: [
        if (requirement.fuelType != 'Any')
          CarSpecItem(icon: Icons.local_gas_station_outlined, label: requirement.fuelType),
        if (requirement.transmission != 'Any')
          CarSpecItem(icon: Icons.tune, label: requirement.transmission),
        if (requirement.bodyType != null)
          CarSpecItem(icon: Icons.directions_car_outlined, label: requirement.bodyType!),
        CarSpecItem(
          icon: Icons.local_offer_outlined,
          label: requirement.quotesReceived == 1 ? '1 quote' : '${requirement.quotesReceived} quotes',
          color: AppColors.success,
        ),
      ],
      primaryAction: FilledButton(
        onPressed: onViewQuotes,
        child: Text(
          requirement.quotesReceived > 0
              ? 'View ${requirement.quotesReceived} quotes'
              : 'View request',
        ),
      ),
    );
  }
}
