import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/master_data/master_data.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/repositories/sell_repository.dart';

/// Four steps: the car, its condition, price and timing, then a review. Each step is checked
/// before moving on, and the listing is sent once (the button locks while it is sending).
class PostSellListingScreen extends ConsumerStatefulWidget {
  const PostSellListingScreen({super.key});

  @override
  ConsumerState<PostSellListingScreen> createState() =>
      _PostSellListingScreenState();
}

class _PostSellListingScreenState extends ConsumerState<PostSellListingScreen> {
  static const _urgencies = {
    'URGENT': ('Sell fast', 'Offers for 2 days'),
    'NORMAL': ('Balanced', 'Offers for 14 days'),
    'MAX_PRICE': ('Best price', 'Offers for 5 days, then decide'),
  };

  final _keys = List.generate(3, (_) => GlobalKey<FormState>());
  final _variant = TextEditingController();
  final _km = TextEditingController();
  final _loanAmount = TextEditingController();
  final _challans = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  int _step = 0;
  bool _sending = false;
  String? _make;
  String? _model;
  int? _year;
  String? _fuel;
  String? _transmission;
  String? _color;
  int _owners = 1;
  bool? _insuranceValid;
  bool _loan = false;
  String? _city;
  String _urgency = 'NORMAL';

  @override
  void dispose() {
    for (final c in [
      _variant,
      _km,
      _loanAmount,
      _challans,
      _description,
      _price,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  String? _required(Object? v) => v == null ? 'Required' : null;

  String? _number(
    String? v, {
    required int min,
    required int max,
    bool optional = false,
  }) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return optional ? null : 'Required';
    final n = int.tryParse(text);
    if (n == null) return 'Enter numbers only';
    if (n < min || n > max) return 'Between $min and $max';
    return null;
  }

  Future<void> _next() async {
    if (_step < 3) {
      if (!(_keys[_step].currentState?.validate() ?? false)) return;
      setState(() => _step++);
      return;
    }
    final draft = SellDraft(
      make: _make!,
      model: _model!,
      variant: _variant.text,
      year: _year!,
      fuel: _fuel!,
      transmission: _transmission!,
      color: _color,
      km: _int(_km)!,
      owners: _owners,
      insuranceValid: _insuranceValid,
      loanOutstanding: _loan,
      loanAmount: _loan ? _int(_loanAmount) : null,
      challansAmount: _int(_challans),
      description: _description.text,
      expectedPrice: _int(_price)!,
      city: _city!,
      urgency: _urgency,
    );
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(sellRepositoryProvider).create(draft);
      ref.invalidate(sellListingsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Listed. Matching dealers have been told.'),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final md = ref.watch(masterDataProvider).valueOrNull ?? MasterData.bundled;
    final thisYear = DateTime.now().year + 1;
    final years = [for (var y = thisYear; y >= md.minYear; y--) y];

    return Scaffold(
      appBar: AppBar(title: const Text('Sell your car')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _sending ? null : _next,
        onStepCancel: _sending || _step == 0
            ? null
            : () => setState(() => _step--),
        // Only the open step gets buttons; the others would be duplicates for screen readers.
        controlsBuilder: (context, details) => details.stepIndex != _step
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_step == 3 ? 'List my car' : 'Continue'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_step > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              ),
        steps: [
          Step(
            title: const Text('The car'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _keys[0],
              child: Column(
                children: [
                  _dropdown<String>(
                    'Make',
                    _make,
                    md.makeNames,
                    (v) => setState(() {
                      _make = v;
                      _model = null;
                    }),
                  ),
                  _dropdown<String>(
                    'Model',
                    _model,
                    md.modelsOf(_make),
                    (v) => setState(() => _model = v),
                  ),
                  _field(_variant, 'Variant (optional)', hint: 'e.g. ZXi AMT'),
                  _dropdown<int>(
                    'Year',
                    _year,
                    years,
                    (v) => setState(() => _year = v),
                  ),
                  _dropdown<String>(
                    'Fuel',
                    _fuel,
                    md.fuels,
                    (v) => setState(() => _fuel = v),
                  ),
                  _dropdown<String>(
                    'Transmission',
                    _transmission,
                    md.transmissions,
                    (v) => setState(() => _transmission = v),
                  ),
                  _dropdown<String>(
                    'Colour (optional)',
                    _color,
                    md.colors,
                    (v) => setState(() => _color = v),
                    optional: true,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Condition'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _keys[1],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    _km,
                    'Kilometres driven',
                    numeric: true,
                    validator: (v) => _number(v, min: 0, max: 1000000),
                  ),
                  _dropdown<int>(
                    'Owners so far',
                    _owners,
                    const [1, 2, 3, 4, 5, 6],
                    (v) => setState(() => _owners = v ?? 1),
                    itemLabel: (n) => n == 1 ? '1st owner' : '$n owners',
                  ),
                  const Text('Insurance'),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<bool?>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('Valid')),
                      ButtonSegment(value: false, label: Text('Expired')),
                    ],
                    selected: {_insuranceValid},
                    onSelectionChanged: (s) => setState(
                      () => _insuranceValid = s.isEmpty ? null : s.first,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('A loan is still running on this car'),
                    subtitle: const Text(
                      'Dealers will allow for settling it in their offer.',
                    ),
                    value: _loan,
                    onChanged: (v) => setState(() => _loan = v),
                  ),
                  if (_loan)
                    _field(
                      _loanAmount,
                      'Approx. amount outstanding (₹, optional)',
                      numeric: true,
                      validator: (v) =>
                          _number(v, min: 0, max: 500000000, optional: true),
                    ),
                  _field(
                    _challans,
                    'Pending challans (₹, optional)',
                    numeric: true,
                    validator: (v) =>
                        _number(v, min: 0, max: 10000000, optional: true),
                  ),
                  _field(
                    _description,
                    'Anything dealers should know (optional)',
                    maxLength: 1000,
                    lines: 3,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Price and timing'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _keys[2],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    _price,
                    'Expected price (₹)',
                    numeric: true,
                    validator: (v) => _number(v, min: 10000, max: 500000000),
                    onChanged: (_) => setState(() {}),
                    helper: _int(_price) == null
                        ? null
                        : PriceFormatter.formatINR(_int(_price)!),
                  ),
                  _dropdown<String>(
                    'City',
                    _city,
                    md.cities,
                    (v) => setState(() => _city = v),
                  ),
                  const Text('How soon do you want to sell?'),
                  const SizedBox(height: AppSpacing.xs),
                  RadioGroup<String>(
                    groupValue: _urgency,
                    onChanged: (v) => setState(() => _urgency = v ?? 'NORMAL'),
                    child: Column(
                      children: [
                        for (final u in _urgencies.entries)
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: u.key,
                            title: Text(u.value.$1),
                            subtitle: Text(u.value.$2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _step >= 3,
            content: _Review(
              rows: [
                (
                  'Car',
                  [
                    _year,
                    _make,
                    _model,
                    _variant.text.trim(),
                  ].where((e) => e != null && '$e'.isNotEmpty).join(' '),
                ),
                ('Fuel / gearbox', '${_fuel ?? '-'} · ${_transmission ?? '-'}'),
                (
                  'Driven',
                  '${_km.text} km · ${_owners == 1 ? '1st owner' : '$_owners owners'}',
                ),
                ('Loan running', _loan ? 'Yes' : 'No'),
                (
                  'Expected price',
                  _int(_price) == null
                      ? '-'
                      : PriceFormatter.formatINR(_int(_price)!),
                ),
                ('City', _city ?? '-'),
                (
                  'Offers open for',
                  _urgencies[_urgency]!.$2.replaceFirst('Offers for ', ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    bool numeric = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? helper,
    int? maxLength,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextFormField(
      controller: c,
      enabled: !_sending,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      maxLength: maxLength,
      maxLines: lines,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    bool optional = false,
    String Function(T)? itemLabel,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: optional ? null : _required,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final i in items)
          DropdownMenuItem(
            value: i,
            child: Text(itemLabel == null ? '$i' : itemLabel(i)),
          ),
      ],
      onChanged: _sending ? null : onChanged,
    ),
  );
}

class _Review extends StatelessWidget {
  final List<(String, String)> rows;
  const _Review({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    r.$1,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Expanded(child: Text(r.$2)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Verified dealers who buy this make near you will see your listing and send offers. Your phone number stays hidden until you accept one.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
