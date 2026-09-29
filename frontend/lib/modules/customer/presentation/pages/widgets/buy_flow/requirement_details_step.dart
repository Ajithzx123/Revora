import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/revora_theme_colors.dart';
import '../../../providers/car_selection_provider.dart';

class RequirementDetailsStep extends StatefulWidget {
  final CarSelectionState state;
  final Function({
    int? minYear,
    int? maxYear,
    double? minBudget,
    double? maxBudget,
    String? fuelType,
    String? transmission,
    String? preferredCity,
  }) onUpdate;
  final VoidCallback onContinue;

  const RequirementDetailsStep({
    super.key,
    required this.state,
    required this.onUpdate,
    required this.onContinue,
  });

  @override
  State<RequirementDetailsStep> createState() => _RequirementDetailsStepState();
}

class _RequirementDetailsStepState extends State<RequirementDetailsStep> {
  late RangeValues _yearRange;
  late RangeValues _budgetRange;
  late String _selectedFuel;
  late String _selectedTransmission;
  late String _selectedCity;

  final List<String> fuelOptions = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];
  final List<String> transmissionOptions = ['Automatic', 'Manual', 'Any'];
  final List<String> cityOptions = [
    'Bengaluru',
    'Mumbai',
    'Delhi NCR',
    'Hyderabad',
    'Chennai',
    'Pune',
    'Ahmedabad',
    'Kolkata',
  ];

  @override
  void initState() {
    super.initState();
    _yearRange = RangeValues(
      widget.state.minYear.toDouble(),
      widget.state.maxYear.toDouble(),
    );
    _budgetRange = RangeValues(
      widget.state.minBudget,
      widget.state.maxBudget,
    );
    _selectedFuel = widget.state.fuelType;
    _selectedTransmission = widget.state.transmission;
    _selectedCity = widget.state.preferredCity;
  }

  void _syncState() {
    widget.onUpdate(
      minYear: _yearRange.start.round(),
      maxYear: _yearRange.end.round(),
      minBudget: _budgetRange.start,
      maxBudget: _budgetRange.end,
      fuelType: _selectedFuel,
      transmission: _selectedTransmission,
      preferredCity: _selectedCity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preference & Budget Details',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Set your acceptable manufacturing year, budget range, and fuel preference',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 1. Year Range
        _buildSectionCard(
          cs: cs,
          colors: colors,
          title: 'Manufacture Year',
          subtitle: '${_yearRange.start.round()} - ${_yearRange.end.round()}',
          child: Column(
            children: [
              RangeSlider(
                values: _yearRange,
                min: 2015,
                max: 2025,
                divisions: 10,
                activeColor: cs.secondary,
                inactiveColor: colors.progressBg,
                labels: RangeLabels(
                  '${_yearRange.start.round()}',
                  '${_yearRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _yearRange = values);
                  _syncState();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2015', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    Text('2025', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Budget Range
        _buildSectionCard(
          cs: cs,
          colors: colors,
          title: 'Budget Range',
          subtitle: '₹${(_budgetRange.start / 100000).toStringAsFixed(1)}L - ₹${(_budgetRange.end / 100000).toStringAsFixed(1)}L',
          child: Column(
            children: [
              RangeSlider(
                values: _budgetRange,
                min: 200000,
                max: 5000000,
                divisions: 48,
                activeColor: cs.secondary,
                inactiveColor: colors.progressBg,
                labels: RangeLabels(
                  '₹${(_budgetRange.start / 100000).toStringAsFixed(1)}L',
                  '₹${(_budgetRange.end / 100000).toStringAsFixed(1)}L',
                ),
                onChanged: (values) {
                  setState(() => _budgetRange = values);
                  _syncState();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹2 Lakh', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    Text('₹50 Lakh', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Fuel Type
        _buildSectionCard(
          cs: cs,
          colors: colors,
          title: 'Fuel Type',
          subtitle: _selectedFuel,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fuelOptions.map((fuel) {
              final isSelected = _selectedFuel == fuel;

              return ChoiceChip(
                label: Text(fuel),
                selected: isSelected,
                selectedColor: cs.secondary,
                backgroundColor: colors.chipBg,
                side: BorderSide(
                  color: isSelected ? cs.secondary : colors.chipBorder,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFuel = fuel);
                    _syncState();
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. Transmission
        _buildSectionCard(
          cs: cs,
          colors: colors,
          title: 'Transmission',
          subtitle: _selectedTransmission,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transmissionOptions.map((trans) {
              final isSelected = _selectedTransmission == trans;

              return ChoiceChip(
                label: Text(trans),
                selected: isSelected,
                selectedColor: cs.secondary,
                backgroundColor: colors.chipBg,
                side: BorderSide(
                  color: isSelected ? cs.secondary : colors.chipBorder,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTransmission = trans);
                    _syncState();
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 5. City
        _buildSectionCard(
          cs: cs,
          colors: colors,
          title: 'Preferred City',
          subtitle: _selectedCity,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            dropdownColor: colors.cardBg,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.searchBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.searchBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.searchBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: cityOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCity = val);
                _syncState();
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Review Requirement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required ColorScheme cs,
    required RevoraThemeColors colors,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
