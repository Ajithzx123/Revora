import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/repositories/buy_leads_repository.dart';
import '../../domain/repositories/dealer_quotes_repository.dart';
import '../providers/dealer_providers.dart';

/// Build a quote for one buyer request: pick the car (or quote a car you will source),
/// set the all-in price, how long it holds, delivery and warranty.
class SendQuoteScreen extends ConsumerStatefulWidget {
  final String leadId;

  const SendQuoteScreen({super.key, required this.leadId});

  @override
  ConsumerState<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends ConsumerState<SendQuoteScreen> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _delivery = TextEditingController();
  final _warranty = TextEditingController();
  String? _carId;
  int _validHours = 72;
  bool _sending = false;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    _delivery.dispose();
    _warranty.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim());

  Future<void> _send(bool sourced) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(dealerQuotesRepositoryProvider)
          .send(
            QuoteDraft(
              requirementId: widget.leadId,
              vehicleId: sourced ? null : _carId,
              price: _int(_price)!,
              message: _note.text,
              validHours: _validHours,
              deliveryDays: _int(_delivery),
              warrantyMonths: _int(_warranty),
            ),
          );
      ref.invalidate(myQuotesProvider);
      ref.invalidate(buyLeadsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Quote sent. You will be told if the buyer counters.'),
        ),
      );
      if (router.canPop()) router.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final inventory = ref
        .watch(dealerInventoryProvider)
        .where((v) => v.isAvailable)
        .toList();
    final leads = ref
        .watch(dealerBuyLeadsProvider)
        .where((l) => l.id == widget.leadId);
    final lead = leads.isEmpty ? null : leads.first;

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send quote')),
        body: const Center(
          child: Text('This request is no longer available to you.'),
        ),
      );
    }
    // A sourcing match has no car of yours behind it; the quote is for a car you will find.
    final sourced = lead.matchTier == 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Send quote')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
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
                        Text(lead.title, style: t.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Budget up to ${PriceFormatter.formatINR(lead.maxBudget)} · ${lead.customerCity} · ${lead.fuelType}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (sourced) ...[
                    Text('You will source this car', style: t.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'The buyer sees that the car is not in your stock yet. Say how many days delivery will take.',
                      style: t.bodySmall,
                    ),
                  ] else ...[
                    Text('Which car are you quoting?', style: t.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    if (inventory.isEmpty)
                      Text(
                        'You have no available cars. Add one to your inventory first.',
                        style: t.bodySmall,
                      )
                    else
                      RadioGroup<String>(
                        groupValue: _carId,
                        onChanged: (v) => setState(() {
                          _carId = v;
                          final car = inventory.firstWhere((c) => c.id == v);
                          _price.text = car.price.round().toString();
                        }),
                        child: Column(
                          children: [
                            for (final car in inventory)
                              RadioListTile<String>(
                                value: car.id,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${car.year} ${car.make} ${car.model}',
                                ),
                                subtitle: Text(
                                  '${PriceFormatter.formatINR(car.price)} · ${PriceFormatter.formatKm(car.mileage)} · ${car.fuelType}',
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total price the buyer pays (₹)',
                      helperText:
                          'Include everything: registration, handling and delivery. The buyer sees this exact amount.',
                      helperMaxLines: 2,
                      prefixIcon: Icon(Icons.currency_rupee, size: 20),
                    ),
                    validator: (v) {
                      final n = int.tryParse(
                        (v ?? '').replaceAll(',', '').trim(),
                      );
                      if (n == null || n <= 0) return 'Enter the total price';
                      if (n > 500000000) return 'That looks too high';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _delivery,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Delivery in (days)',
                          ),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) {
                              return sourced ? 'Required' : null;
                            }
                            final n = int.tryParse(v!.trim());
                            return n == null || n < 0 || n > 180
                                ? '0 to 180'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _warranty,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Warranty (months)',
                          ),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return null;
                            final n = int.tryParse(v!.trim());
                            return n == null || n < 0 || n > 120
                                ? '0 to 120'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: _validHours,
                    decoration: const InputDecoration(
                      labelText: 'Price holds for',
                    ),
                    items: const [
                      DropdownMenuItem(value: 24, child: Text('24 hours')),
                      DropdownMenuItem(value: 48, child: Text('2 days')),
                      DropdownMenuItem(value: 72, child: Text('3 days')),
                      DropdownMenuItem(value: 168, child: Text('7 days')),
                    ],
                    onChanged: (v) => setState(() => _validHours = v ?? 72),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _note,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Note to the buyer (optional)',
                      hintText: 'e.g. First owner, service history available',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sending || (!sourced && _carId == null)
                          ? null
                          : () => _send(sourced),
                      child: Text(_sending ? 'Sending…' : 'Send quote'),
                    ),
                  ),
                  if (!sourced && _carId == null && inventory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Choose a car to continue.',
                        style: t.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
