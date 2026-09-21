import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../domain/entities/quote.dart';

class CustomerQuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onAccept;
  final VoidCallback? onContact;
  final bool isHomeScreen;
  final double? imageHeight;

  const CustomerQuoteCard({
    super.key,
    required this.quote,
    this.onAccept,
    this.onContact,
    this.isHomeScreen = false,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CarCard(
      imageHeight: imageHeight,
      imageUrl: quote.carImageUrl,
      title: quote.carTitle,
      subtitle: isHomeScreen ? 'Based on your search history' : null,
      location: '${quote.dealerName} • ${quote.dealerCity}',
      priceText: quote.formattedPrice,
      priceLabel: 'Price',
      badgeText: isHomeScreen ? '🔥 FEATURED' : '${quote.matchPercentage}% Match',
      badgeBgColor: isHomeScreen ? const Color(0xFFFFECEE) : const Color(0xFFF1F5F9),
      badgeTextColor: isHomeScreen ? AppColors.error : AppColors.textPrimary,
      specs: [
        CarSpecItem(
          icon: Icons.calendar_today_outlined,
          label: '${quote.carYear}',
        ),
        CarSpecItem(
          icon: Icons.speed,
          label: '${(quote.carMileage / 1000).toStringAsFixed(0)}k km',
        ),
        CarSpecItem(
          icon: Icons.local_gas_station_outlined,
          label: quote.carFuel,
        ),
        CarSpecItem(
          icon: Icons.star_rounded,
          label: quote.dealerRating.toStringAsFixed(1),
          color: Colors.amber.shade700,
        ),
      ],
      secondaryAction: OutlinedButton(
        onPressed: onContact,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
        child: const Text(
          'Contact',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      primaryAction: ElevatedButton(
        onPressed: onAccept,
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
          'Accept Deal',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
