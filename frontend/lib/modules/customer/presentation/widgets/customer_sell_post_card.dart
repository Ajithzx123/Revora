import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../domain/entities/sell_post.dart';

class CustomerSellPostCard extends StatelessWidget {
  final SellPost post;
  final VoidCallback? onViewOffers;

  const CustomerSellPostCard({
    super.key,
    required this.post,
    this.onViewOffers,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a badge color based on status
    Color badgeColor;
    Color badgeTextColor = Colors.white;
    switch (post.status.toLowerCase()) {
      case 'active':
        badgeColor = AppColors.success;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        break;
      case 'sold':
        badgeColor = AppColors.primary;
        break;
      default:
        badgeColor = AppColors.textSecondary;
    }

    return CarCard(
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
      title: post.title,
      location: 'Posted recently',
      priceText: post.formattedPrice,
      priceLabel: 'Expected Price',
      badgeText: post.status.toUpperCase(),
      badgeBgColor: badgeColor,
      badgeTextColor: badgeTextColor,
      specs: [
        CarSpecItem(
          icon: Icons.speed,
          label: '${(post.mileage / 1000).toStringAsFixed(0)}k km',
        ),
        CarSpecItem(
          icon: Icons.local_gas_station_outlined,
          label: post.fuelType,
        ),
        CarSpecItem(
          icon: Icons.tune,
          label: post.transmission,
        ),
        CarSpecItem(
          icon: Icons.local_offer_outlined,
          label: '${post.offersCount} Offers',
          color: AppColors.success,
        ),
      ],
      primaryAction: ElevatedButton(
        onPressed: onViewOffers,
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
          'View ${post.offersCount} Offers',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
