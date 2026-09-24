import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/revora_theme_colors.dart';
import '../../../providers/car_selection_provider.dart';

class ReviewSubmitStep extends StatelessWidget {
  final CarSelectionState state;
  final VoidCallback onEditBrand;
  final VoidCallback onEditModel;
  final VoidCallback onEditVariant;
  final VoidCallback onEditDetails;
  final VoidCallback onSubmit;

  const ReviewSubmitStep({
    super.key,
    required this.state,
    required this.onEditBrand,
    required this.onEditModel,
    required this.onEditVariant,
    required this.onEditDetails,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;
    final isDark = theme.brightness == Brightness.dark;

    final heroCardBg = [colors.gradientStart, colors.gradientEnd];
    final heroBorder = cs.secondary.withValues(alpha: isDark ? 0.5 : 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Broadcast Requirement',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),


        // Hero Card with Car Summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: heroCardBg,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: heroBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? cs.secondary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: const Text(
                      'READY TO BROADCAST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Icon(Icons.verified_rounded, color: cs.secondary, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${state.selectedBrand ?? ""} ${state.selectedModel ?? ""}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.selectedVariant != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Variant: ${state.selectedVariant}',
                  style: TextStyle(
                    color: cs.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Divider(color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: AppSpacing.sm),

              _buildSummaryRow(
                'Budget Range',
                '₹${(state.minBudget / 100000).toStringAsFixed(1)} - ${(state.maxBudget / 100000).toStringAsFixed(1)} Lakh',
                Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'Year Model',
                '${state.minYear} - ${state.maxYear}',
                Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'Fuel & Transmission',
                '${state.fuelType} • ${state.transmission}',
                Icons.local_gas_station_outlined,
              ),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'Preferred City',
                state.preferredCity,
                Icons.location_on_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Dealer Network Guarantee Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.statusSuccessBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: colors.statusSuccessFg,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero spam, 100% verified dealers only',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only certified dealers who have matching stock will be permitted to quote.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              elevation: 3,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Post Requirement to Dealers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$title:',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
