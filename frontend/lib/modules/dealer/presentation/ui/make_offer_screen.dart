import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/entities/sell_lead.dart';
import '../../domain/procurement_calculator.dart';
import '../../domain/repositories/dealer_offers_repository.dart';

/// Price a purchase offer on a matched car: a procurement calculator (cost, margin, the most
/// you can pay for a target margin) above the offer form. The offer is sealed: the seller sees
/// it, other dealers never do.
class MakeOfferScreen extends ConsumerWidget {
  final String listingId;

  const MakeOfferScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(sellLeadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Make a purchase offer')),
      body: leads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(sellLeadsProvider),
        ),
        data: (list) {
          final match = list.where((l) => l.id == listingId);
          if (match.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.directions_car_outlined,
              title: 'This car is no longer available',
              description: 'The seller may have closed the listing.',
            );
          }
          return _OfferForm(lead: match.first);
        },
      ),
    );
  }
}

class _OfferForm extends ConsumerStatefulWidget {
  final SellLead lead;
  const _OfferForm({required this.lead});

  @override
  ConsumerState<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends ConsumerState<_OfferForm> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: widget.lead.listing.expectedPrice.toString(),
  );
  final _message = TextEditingController();
  final _pickup = TextEditingController();
  final _refurb = TextEditingController();
  final _rto = TextEditingController();
  final _holding = TextEditingController();
  final _resale = TextEditingController();
  final _target = TextEditingController(text: '8');
  int _validHours = 48;
  bool _inspection = true;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [
      _price,
      _message,
      _pickup,
      _refurb,
      _rto,
      _holding,
      _resale,
      _target,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  ProcurementInputs get _inputs => ProcurementInputs(
    offer: _n(_price),
    refurbishment: _n(_refurb),
    transferRto: _n(_rto),
    holding: _n(_holding),
    expectedResale: _n(_resale),
    loanSettlement: widget.lead.listing.loanAmount ?? 0,
    challans: widget.lead.listing.challansAmount ?? 0,
  );

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final draft = OfferDraft(
      listingId: widget.lead.id,
      price: _n(_price),
      message: _message.text,
      validHours: _validHours,
      inspectionRequired: _inspection,
      pickupDays: _pickup.text.trim().isEmpty ? null : _n(_pickup),
    );
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(dealerOffersRepositoryProvider).send(draft);
      ref.invalidate(sellLeadsProvider);
      ref.invalidate(myOffersProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Offer sent to the seller.')),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  String? _money(String? v, {bool optional = false, int max = 500000000}) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return optional ? null : 'Required';
    final n = int.tryParse(text);
    if (n == null) return 'Enter numbers only';
    if (!optional && n <= 0) return 'Must be more than zero';
    if (n > max) return 'Too large';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.lead.listing;
    final t = Theme.of(context).textTheme;
    final result = ProcurementCalculator.calculate(_inputs);
    final target = double.tryParse(_target.text.trim()) ?? 0;
    final suggested = _n(_resale) > 0
        ? ProcurementCalculator.maxOfferForMargin(_inputs, target)
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CarSummary(lead: widget.lead),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Procurement calculator',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Estimate your margin before you offer. Nothing here is sent to the seller.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                _moneyField(
                  _resale,
                  'Expected resale price (₹)',
                  optional: true,
                ),
                _moneyField(_refurb, 'Refurbishment (₹)', optional: true),
                _moneyField(_rto, 'Transfer / RTO (₹)', optional: true),
                _moneyField(_holding, 'Holding cost (₹)', optional: true),
                _moneyField(
                  _target,
                  'Target margin (%)',
                  optional: true,
                  max: 100,
                ),
                const SizedBox(height: AppSpacing.sm),
                _Results(
                  result: result,
                  suggested: suggested,
                  hasResale: _n(_resale) > 0,
                  car: car.loanOutstanding || (car.challansAmount ?? 0) > 0,
                ),
                if (suggested > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _price.text = suggested.toString()),
                      child: Text(
                        'Use ${PriceFormatter.formatINR(suggested)} as my offer',
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Your offer',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                _moneyField(
                  _price,
                  'Offer price (₹)',
                  onChanged: true,
                  validator: (v) => _money(v),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _validHours,
                  decoration: const InputDecoration(
                    labelText: 'Offer holds for',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 24, child: Text('24 hours')),
                    DropdownMenuItem(value: 48, child: Text('48 hours')),
                    DropdownMenuItem(value: 72, child: Text('3 days')),
                    DropdownMenuItem(value: 168, child: Text('7 days')),
                  ],
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _validHours = v ?? 48),
                ),
                const SizedBox(height: AppSpacing.md),
                _moneyField(
                  _pickup,
                  'Pickup within (days, optional)',
                  optional: true,
                  max: 60,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Subject to inspection'),
                  subtitle: const Text(
                    'The final price is confirmed after you inspect the car.',
                  ),
                  value: _inspection,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _inspection = v),
                ),
                TextFormField(
                  controller: _message,
                  enabled: !_sending,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note to the seller (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send offer'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'The seller sees your price and conditions. Other dealers never do.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moneyField(
    TextEditingController c,
    String label, {
    bool optional = false,
    int max = 500000000,
    bool onChanged = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextFormField(
      controller: c,
      enabled: !_sending,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator ?? (v) => _money(v, optional: optional, max: max),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _CarSummary extends StatelessWidget {
  final SellLead lead;
  const _CarSummary({required this.lead});

  @override
  Widget build(BuildContext context) {
    final car = lead.listing;
    final t = Theme.of(context).textTheme;
    return Container(
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
            car.title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${car.city} · ${PriceFormatter.formatKm(car.mileage)} · ${car.fuelType} · ${car.transmission} · ${car.owners == 1 ? '1st owner' : '${car.owners} owners'}',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Seller asks ${PriceFormatter.formatINR(car.expectedPrice)}',
            style: t.titleSmall,
          ),
          if (car.loanOutstanding)
            Text(
              'Loan running${car.loanAmount == null ? '' : ' (about ${PriceFormatter.formatINR(car.loanAmount!)})'}. Settlement is part of the deal.',
              style: t.bodySmall,
            ),
          if ((car.challansAmount ?? 0) > 0)
            Text(
              'Pending challans: ${PriceFormatter.formatINR(car.challansAmount!)}',
              style: t.bodySmall,
            ),
          if (car.insuranceValid == false)
            Text('Insurance has expired', style: t.bodySmall),
          if ((car.description ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(car.description!, style: t.bodySmall),
          ],
          if (lead.matchReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Why you: ${lead.matchReasons.join(' · ')}',
              style: t.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final ProcurementResult result;
  final int suggested;
  final bool hasResale;
  final bool car;
  const _Results({
    required this.result,
    required this.suggested,
    required this.hasResale,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    final good = result.profitable;
    Widget row(String l, String v, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(l)),
              Text(
                v,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : null,
                  color: color,
                ),
              ),
            ],
          ),
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          row('Your total cost', PriceFormatter.formatINR(result.totalCost)),
          if (hasResale) ...[
            row(
              'Gross margin',
              '${PriceFormatter.formatINR(result.grossMargin)} (${result.marginPercent.toStringAsFixed(1)}%)',
              bold: true,
              color: good ? AppColors.success : AppColors.error,
            ),
            if (!good)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Loss at this price',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            row(
              'Most you can offer for your target',
              suggested == 0 ? 'None' : PriceFormatter.formatINR(suggested),
            ),
          ] else
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter an expected resale price to see your margin.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (car)
            row(
              'Seller receives after loan / challans',
              PriceFormatter.formatINR(result.sellerReceives),
            ),
        ],
      ),
    );
  }
}
