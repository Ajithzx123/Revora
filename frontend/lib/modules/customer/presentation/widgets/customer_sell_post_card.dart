import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
        badgeColor = AppColors.warning;
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
      priceLabel: 'Asking',
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
        CarSpecItem(icon: Icons.tune, label: post.transmission),
        CarSpecItem(
          icon: Icons.local_offer_outlined,
          label: post.offersCount == 1
              ? '1 offer'
              : '${post.offersCount} offers',
          color: AppColors.success,
        ),
      ],
      primaryAction: FilledButton(
        onPressed: onViewOffers,
        child: Text(
          post.offersCount == 1
              ? 'View 1 offer'
              : 'View ${post.offersCount} offers',
        ),
      ),
    );
  }
}
