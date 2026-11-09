import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/master_data/master_data.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/buy_requirement.dart';
import '../../domain/entities/requirement_draft.dart';
import '../providers/customer_providers.dart';
import '../providers/requirements_provider.dart';

/// Post (or edit) a buy request in three short steps:
/// 1. the car  2. budget and place  3. preferences and review.
/// Only the make, budget and city are required; everything else narrows the match.
class PostBuyRequirementScreen extends ConsumerStatefulWidget {
  /// When set, the form edits this request instead of creating a new one.
  final BuyRequirement? existing;

  const PostBuyRequirementScreen({super.key, this.existing});

  @override
  ConsumerState<PostBuyRequirementScreen> createState() =>
      _PostBuyRequirementScreenState();
}

class _PostBuyRequirementScreenState
    extends ConsumerState<PostBuyRequirementScreen> {
  static const _stepTitles = ['The car', 'Budget & place', 'Review'];

  late final RequirementDraft _draft;
  final _notes = TextEditingController();
  final _scroll = ScrollController();
  int _step = 0;
  bool _submitting = false;
  String? _error;
  String? _stepError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing != null
        ? RequirementDraft.from(widget.existing!)
        : RequirementDraft();
    if (!_editing) {
      _draft.budgetMin = 500000;
      _draft.budgetMax = 1000000;
    }
    _notes.text = _draft.notes ?? '';
  }

  @override
  void dispose() {
    _scroll.dispose();
    _notes.dispose();
    super.dispose();
  }

  // ---- navigation ----
  bool _validateStep() {
    String? problem;
    if (_step == 0 && _draft.make == null) {
      problem = 'Choose a make to continue.';
    }
    if (_step == 1 && _draft.city == null) {
      problem = 'Choose your city to continue.';
    }
    setState(() => _stepError = problem);
    if (problem != null) _showTop();
    return problem == null;
  }

  void _showTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    if (!_validateStep()) return;
    HapticFeedback.selectionClick();
    setState(() {
      _step++;
      _error = null;
    });
  }

  void _back() => setState(() {
    _step--;
    _stepError = null;
  });

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    _draft.notes = _notes.text;
    try {
      final notifier = ref.read(requirementsProvider.notifier);
      if (_editing) {
        await notifier.edit(widget.existing!.id, _draft);
      } else {
        await notifier.create(_draft);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.read(customerActiveTabProvider.notifier).state = 1;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Request updated.'
                : 'Request posted. Verified dealers can now send you quotes.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = apiErrorMessage(e));
        _showTop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    final masterData =
        ref.watch(masterDataProvider).valueOrNull ?? MasterData.bundled;
    final t = Theme.of(context).textTheme;
    final last = _step == _stepTitles.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit request' : 'Post a request'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Progress(step: _step, titles: _stepTitles),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            'What car do you want?',
                            'How much, and where?',
                            'Check and post',
                          ][_step],
                          style: t.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          [
                            'Pick the make. Everything else is optional.',
                            'Dealers within your radius will see this.',
                            'Add any must-haves, then post. You can edit it later.',
                          ][_step],
                          style: t.bodySmall,
                        ),
                        if (_stepError != null) _Banner(message: _stepError!),
                        if (_error != null) _Banner(message: _error!),
                        const SizedBox(height: AppSpacing.xl),
                        if (_step == 0) _stepCar(masterData),
                        if (_step == 1) _stepBudget(masterData),
                        if (_step == 2) _stepReview(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        OutlinedButton(
                          onPressed: _submitting ? null : _back,
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : (last ? _submit : _next),
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  last
                                      ? (_editing
                                            ? 'Save changes'
                                            : 'Post request')
                                      : 'Continue',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- step 1: the car ----
  Widget _stepCar(MasterData md) {
    final models = md.modelsOf(_draft.make);
    final currentYear = DateTime.now().year;
    final maxYear = currentYear + 1;
    final yearEnd = (_draft.yearMax ?? maxYear).clamp(_draft.yearMin, maxYear);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Make'),
        DropdownButtonFormField<String>(
          initialValue: _draft.make,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(hintText: 'Select a make'),
          items: [
            for (final m in md.makeNames)
              DropdownMenuItem(value: m, child: Text(m)),
          ],
          onChanged: (v) => setState(() {
            _draft.make = v;
            _draft.model = null; // a model belongs to one make
            _stepError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label('Model'),
        DropdownButtonFormField<String?>(
          key: ValueKey(_draft.make),
          initialValue: _draft.model,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            hintText: _draft.make == null ? 'Choose a make first' : 'Any model',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Any model'),
            ),
            for (final m in models)
              DropdownMenuItem<String?>(value: m, child: Text(m)),
          ],
          onChanged: _draft.make == null
              ? null
              : (v) => setState(() => _draft.model = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label(
          'Registered between',
          trailing: '${_draft.yearMin} - ${_draft.yearMax ?? 'newest'}',
        ),
        RangeSlider(
          values: RangeValues(_draft.yearMin.toDouble(), yearEnd.toDouble()),
          min: md.minYear.toDouble() + 5,
          max: maxYear.toDouble(),
          divisions: maxYear - (md.minYear + 5),
          labels: RangeLabels('${_draft.yearMin}', '$yearEnd'),
          onChanged: (v) => setState(() {
            _draft.yearMin = v.start.round();
            final end = v.end.round();
            _draft.yearMax = end >= maxYear ? null : end;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label('Body type'),
        _ChoiceWrap(
          options: md.bodyTypes,
          selected: _draft.bodyType,
          anyLabel: 'Any',
          onChanged: (v) => setState(() => _draft.bodyType = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label('Fuel'),
        _ChoiceWrap(
          options: md.fuels,
          selected: _draft.fuel,
          anyLabel: 'Any',
          onChanged: (v) => setState(() => _draft.fuel = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label('Transmission'),
        _ChoiceWrap(
          options: md.transmissions,
          selected: _draft.transmission,
          anyLabel: 'Any',
          onChanged: (v) => setState(() => _draft.transmission = v),
        ),
      ],
    );
  }

  // ---- step 2: budget and place ----
  Widget _stepBudget(MasterData md) {
    const minLakh = 1.0;
    const maxLakh = 50.0;
    final lo = (_draft.budgetMin / 100000).clamp(minLakh, maxLakh).toDouble();
    final hi = (_draft.budgetMax / 100000).clamp(minLakh, maxLakh).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Budget'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                PriceFormatter.formatRange(_draft.budgetMin, _draft.budgetMax),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              RangeSlider(
                values: RangeValues(lo, hi),
                min: minLakh,
                max: maxLakh,
                divisions: ((maxLakh - minLakh) * 2).round(),
                labels: RangeLabels(
                  '₹${lo.toStringAsFixed(1)} L',
                  '₹${hi.toStringAsFixed(1)} L',
                ),
                onChanged: (v) => setState(() {
                  _draft.budgetMin = (v.start * 100000).round();
                  _draft.budgetMax = (v.end * 100000).round();
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹1 L', style: Theme.of(context).textTheme.bodySmall),
                  Text('₹50 L', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label('City'),
        DropdownButtonFormField<String>(
          initialValue: _draft.city,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(
            hintText: 'Select your city',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: [
            for (final c in md.cities)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() {
            _draft.city = v;
            _stepError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label('Search within'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final km in const [25, 50, 100, 250])
              ChoiceChip(
                label: Text('$km km'),
                selected: _draft.radiusKm == km,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _draft.radiusKm == km
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _draft.radiusKm = km),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label('How soon do you need it?'),
        for (final (value, title, subtitle) in const [
          ('NOW', 'Right now', 'I want a car this week'),
          ('WITHIN_2_WEEKS', 'In 1-2 weeks', 'I am ready to buy soon'),
          ('WITHIN_60_DAYS', 'In 30-60 days', 'Planning ahead, happy to wait'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChoiceTile(
              title: title,
              subtitle: subtitle,
              selected: _draft.urgency == value,
              onTap: () => setState(() => _draft.urgency = value),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I need a car loan'),
          subtitle: const Text(
            'Dealers can include finance options in their quote',
          ),
          value: _draft.needsFinance,
          onChanged: (v) => setState(() => _draft.needsFinance = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I want to exchange my current car'),
          subtitle: const Text('Dealers can quote a trade-in value'),
          value: _draft.hasExchange,
          onChanged: (v) => setState(() => _draft.hasExchange = v),
        ),
      ],
    );
  }

  // ---- step 3: preferences + review ----
  Widget _stepReview() {
    final t = Theme.of(context).textTheme;

    // A must-have only makes sense for a preference the buyer actually set.
    final mustHaveOptions = <(String key, String label)>[
      if (_draft.fuel != null) ('fuel', 'Fuel: ${_draft.fuel}'),
      if (_draft.transmission != null)
        ('transmission', '${_draft.transmission} gearbox'),
      if (_draft.bodyType != null) ('body_type', _draft.bodyType!),
      if (_draft.maxKm != null)
        ('max_km', 'Under ${PriceFormatter.formatKm(_draft.maxKm!)}'),
      if (_draft.maxOwners != null)
        (
          'max_owners',
          _draft.maxOwners == 1
              ? 'First owner only'
              : 'Up to ${_draft.maxOwners} owners',
        ),
    ];
    _draft.mustHave.removeWhere((k) => !mustHaveOptions.any((o) => o.$1 == k));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(draft: _draft),
        const SizedBox(height: AppSpacing.xl),
        _Label('Maximum kilometres driven'),
        _ChoiceWrap(
          options: const ['20000', '40000', '60000', '80000', '100000'],
          labels: const {
            '20000': '20k',
            '40000': '40k',
            '60000': '60k',
            '80000': '80k',
            '100000': '1 lakh',
          },
          selected: _draft.maxKm?.toString(),
          anyLabel: 'Any',
          onChanged: (v) =>
              setState(() => _draft.maxKm = v == null ? null : int.parse(v)),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Label('Previous owners'),
        _ChoiceWrap(
          options: const ['1', '2', '3'],
          labels: const {'1': 'First owner', '2': 'Up to 2', '3': 'Up to 3'},
          selected: _draft.maxOwners?.toString(),
          anyLabel: 'Any',
          onChanged: (v) => setState(
            () => _draft.maxOwners = v == null ? null : int.parse(v),
          ),
        ),
        if (mustHaveOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _Label('Must-haves'),
          Text(
            'Dealers who cannot match a must-have will not be asked to quote. Everything else is a preference.',
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (key, label) in mustHaveOptions)
                FilterChip(
                  label: Text(label),
                  selected: _draft.mustHave.contains(key),
                  showCheckmark: true,
                  selectedColor: AppColors.accentLight,
                  checkmarkColor: AppColors.accentDeep,
                  onSelected: (on) => setState(
                    () => on
                        ? _draft.mustHave.add(key)
                        : _draft.mustHave.remove(key),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _Label('Anything else dealers should know? (optional)'),
        TextField(
          controller: _notes,
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Colour, features, service history...',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Dealers see your first name and city only. Your phone number stays hidden until you accept a quote.',
                style: t.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- small building blocks ----------
class _Progress extends StatelessWidget {
  final int step;
  final List<String> titles;
  const _Progress({required this.step, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${step + 1} of ${titles.length}: ${titles[step]}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            for (var i = 0; i < titles.length; i++) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step ? AppColors.accent : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titles[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i == step
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: i == step
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < titles.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? trailing;
  const _Label(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(text, style: t.labelLarge)),
          if (trailing != null)
            Text(
              trailing!,
              style: t.labelMedium?.copyWith(color: AppColors.accentDeep),
            ),
        ],
      ),
    );
  }
}

/// "Any" plus a list of options, one selectable at a time. Selecting the chosen one again clears it.
class _ChoiceWrap extends StatelessWidget {
  final List<String> options;
  final Map<String, String> labels;
  final String? selected;
  final String anyLabel;
  final ValueChanged<String?> onChanged;

  const _ChoiceWrap({
    required this.options,
    required this.selected,
    required this.anyLabel,
    required this.onChanged,
    this.labels = const {},
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback tap) => ChoiceChip(
      label: Text(label),
      selected: on,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: on ? Colors.white : AppColors.textPrimary),
      onSelected: (_) => tap(),
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        chip(anyLabel, selected == null, () => onChanged(null)),
        for (final o in options)
          chip(
            labels[o] ?? o,
            selected == o,
            () => onChanged(selected == o ? null : o),
          ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.labelLarge),
                    Text(subtitle, style: t.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.accentDeep : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  const _Banner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final RequirementDraft draft;
  const _SummaryCard({required this.draft});

  String get _years {
    final end = draft.yearMax;
    return end == null ? '${draft.yearMin} or newer' : '${draft.yearMin}-$end';
  }

  String get _urgency => switch (draft.urgency) {
    'NOW' => 'Needs it now',
    'WITHIN_60_DAYS' => 'In 30-60 days',
    _ => 'In 1-2 weeks',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final car = [
      draft.make,
      draft.model ?? 'any model',
    ].whereType<String>().join(' · ');
    final chips = <String>[
      _years,
      if (draft.bodyType != null) draft.bodyType!,
      if (draft.fuel != null) draft.fuel!,
      if (draft.transmission != null) draft.transmission!,
      _urgency,
      if (draft.needsFinance) 'Needs a loan',
      if (draft.hasExchange) 'Exchange',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR REQUEST',
            style: t.labelSmall?.copyWith(
              color: Colors.white60,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(car, style: t.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${PriceFormatter.formatRange(draft.budgetMin, draft.budgetMax)}  ·  ${draft.city ?? '-'}, within ${draft.radiusKm} km',
            style: t.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    c,
                    style: t.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
