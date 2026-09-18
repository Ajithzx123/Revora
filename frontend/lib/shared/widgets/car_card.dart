import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import 'custom_card.dart';
import 'image_container.dart';

class CarCard extends StatelessWidget {
  final String imageUrl;
  final String make;
  final String model;
  final int year;
  final num price;
  final String fuelType;
  final String transmission;
  final num kmDriven;
  final VoidCallback? onTap;

  const CarCard({
    super.key,
    required this.imageUrl,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.fuelType,
    required this.transmission,
    required this.kmDriven,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ImageContainer(
              imageUrl: imageUrl,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$year $make $model',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  PriceFormatter.formatINR(price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSpecChip(context, PriceFormatter.formatKm(kmDriven)),
                    const SizedBox(width: 8),
                    _buildSpecChip(context, fuelType),
                    const SizedBox(width: 8),
                    _buildSpecChip(context, transmission),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
