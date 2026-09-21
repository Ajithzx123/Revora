import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/car_card.dart';
import '../providers/dealer_providers.dart';

class SendQuoteScreen extends ConsumerStatefulWidget {
  final String leadId;

  const SendQuoteScreen({
    super.key,
    required this.leadId,
  });

  @override
  ConsumerState<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends ConsumerState<SendQuoteScreen> {
  String? _selectedCarId;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(dealerInventoryProvider);
    final buyLeads = ref.watch(dealerBuyLeadsProvider);
    final lead = buyLeads.firstWhere(
      (l) => l.id == widget.leadId,
      orElse: () => buyLeads.first,
    );

    // Auto-select first car if none selected
    if (_selectedCarId == null && inventory.isNotEmpty) {
      _selectedCarId = inventory.first.id;
      _priceController.text = inventory.first.price.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Quote'),
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
                  Text(
                    'Buyer Requirement: ${lead.minYear}+ ${lead.make} ${lead.model}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Customer Budget: ${PriceFormatter.formatINR(lead.maxBudget)}  •  ${lead.customerCity}  •  ${lead.fuelType}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Select a car from your inventory to quote:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (inventory.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'No cars in inventory yet. Add cars to your inventory first.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventory.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final car = inventory[index];
                  final isSelected = _selectedCarId == car.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () {
                      setState(() {
                        _selectedCarId = car.id;
                        _priceController.text = car.price.toString();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: SizedBox(
                        height: 380,
                        child: CarCard(
                          imageUrl: car.imageUrl,
                          title: '${car.year} ${car.make} ${car.model}',
                          location: 'In Inventory',
                          priceText: PriceFormatter.formatINR(car.price),
                          badgeText: isSelected ? 'Selected' : 'Available',
                          badgeBgColor: isSelected
                              ? AppColors.accentLight
                              : const Color(0xFFF1F5F9),
                          badgeTextColor: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          showFavorite: false,
                          specs: [
                            CarSpecItem(
                              icon: Icons.calendar_today_outlined,
                              label: '${car.year}',
                            ),
                            CarSpecItem(
                              icon: Icons.speed,
                              label: PriceFormatter.formatKm(car.mileage),
                            ),
                            CarSpecItem(
                              icon: Icons.local_gas_station_outlined,
                              label: car.fuelType,
                            ),
                            CarSpecItem(
                              icon: Icons.tune,
                              label: car.transmission,
                            ),
                          ],
                          primaryAction: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isSelected ? 'Selected Car' : 'Select This Car',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Final Quoted Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee, size: 20),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add a note to customer (Optional)',
                hintText: 'e.g. Certified with 1-year comprehensive warranty',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              text: 'Send Quote to Customer',
              onPressed: _selectedCarId != null
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quote sent successfully to customer!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
