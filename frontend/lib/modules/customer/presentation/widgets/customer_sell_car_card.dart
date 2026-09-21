import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../domain/entities/sell_post.dart';

class CustomerSellCarCard extends StatelessWidget {
  final SellPost post;
  final double? imageHeight;

  const CustomerSellCarCard({
    super.key,
    required this.post,
    this.imageHeight = 110,
  });

  String _formatPostedTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Today (${diff.inHours}h ago)';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Title without year: e.g. "Maruti Suzuki Swift ZXi AMT"
    final carTitle = '${post.make} ${post.model} ${post.variant}'.trim();
    final relativeTime = _formatPostedTime(post.createdAt);

    return CarCard(
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
      title: carTitle,
      subtitle: 'Posted $relativeTime',
      location: null, // Removed location as requested
      priceText: post.formattedPrice,
      priceLabel: 'Price',
      badgeText: post.status.toUpperCase(),
      badgeBgColor: const Color(0xFFEFF6FF),
      badgeTextColor: const Color(0xFF2563EB),
      imageHeight: imageHeight,
      onTap: () => context.push('/customer/listing/${post.id}'),
      specs: [
        // KM is mainly important
        CarSpecItem(
          icon: Icons.speed,
          label: '${(post.mileage / 1000).toStringAsFixed(0)}k km',
          color: AppColors.textPrimary,
        ),
        // Model / Fuel
        CarSpecItem(
          icon: Icons.local_gas_station_outlined,
          label: post.fuelType,
        ),
        CarSpecItem(
          icon: Icons.tune,
          label: post.transmission,
        ),
      ],
      // Replaced contact button with "View Details"
      primaryAction: ElevatedButton(
        onPressed: () => context.push('/customer/listing/${post.id}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
        child: const Text(
          'View Details',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
