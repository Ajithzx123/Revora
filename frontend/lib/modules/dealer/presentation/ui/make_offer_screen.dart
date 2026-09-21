import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../providers/dealer_providers.dart';

class MakeOfferScreen extends ConsumerStatefulWidget {
  final String listingId;

  const MakeOfferScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  late final TextEditingController _offerController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellLeads = ref.watch(dealerSellLeadsProvider);
    final lead = sellLeads.firstWhere(
      (l) => l.id == widget.listingId,
      orElse: () => sellLeads.first,
    );

    if (_offerController.text.isEmpty) {
      _offerController.text = lead.expectedPrice.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Purchase Offer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: Image.network(
                          lead.imageUrl,
                          width: 90,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 90,
                            height: 65,
                            color: AppColors.primarySubtle,
                            child: const Icon(Icons.directions_car,
                                color: AppColors.icon),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lead.year} ${lead.make} ${lead.model}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${PriceFormatter.formatKm(lead.mileage)} • ${lead.fuelType} • ${lead.customerCity}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Asking: ${PriceFormatter.formatINR(lead.expectedPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _offerController,
              decoration: const InputDecoration(
                labelText: 'Your Purchase Offer (₹)',
                prefixIcon: Icon(Icons.currency_rupee, size: 20),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Terms / Notes for Customer',
                hintText:
                    'e.g. Instant payment upon doorstep inspection within 24 hours',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              text: 'Submit Offer to Customer',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Purchase offer submitted successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
