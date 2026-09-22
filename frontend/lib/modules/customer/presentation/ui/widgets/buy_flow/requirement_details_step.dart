import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preference & Budget Details',
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Set your acceptable manufacturing year, budget range, and fuel preference',
          style: TextStyle(color: subtitleColor, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 1. Year Range
        _buildSectionCard(
          isDark: isDark,
          title: 'Manufacture Year',
          subtitle: '${_yearRange.start.round()} - ${_yearRange.end.round()}',
          child: Column(
            children: [
              RangeSlider(
                values: _yearRange,
                min: 2015,
                max: 2025,
                divisions: 10,
                activeColor: AppColors.accent,
                inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
                    Text('2015', style: TextStyle(color: subtitleColor, fontSize: 12)),
                    Text('2025', style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Budget Range
        _buildSectionCard(
          isDark: isDark,
          title: 'Budget Range',
          subtitle: '₹${(_budgetRange.start / 100000).toStringAsFixed(1)}L - ₹${(_budgetRange.end / 100000).toStringAsFixed(1)}L',
          child: Column(
            children: [
              RangeSlider(
                values: _budgetRange,
                min: 200000,
                max: 5000000,
                divisions: 48,
                activeColor: AppColors.accent,
                inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
                    Text('₹2 Lakh', style: TextStyle(color: subtitleColor, fontSize: 12)),
                    Text('₹50 Lakh', style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Fuel Type
        _buildSectionCard(
          isDark: isDark,
          title: 'Fuel Type',
          subtitle: _selectedFuel,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fuelOptions.map((fuel) {
              final isSelected = _selectedFuel == fuel;
              final chipBg = isDark ? const Color(0xFF2B313A) : const Color(0xFFF1F5F9);
              final unselectedText = isDark ? Colors.grey[300] : AppColors.textPrimary;

              return ChoiceChip(
                label: Text(fuel),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: chipBg,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.border),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : unselectedText,
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
          isDark: isDark,
          title: 'Transmission',
          subtitle: _selectedTransmission,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transmissionOptions.map((trans) {
              final isSelected = _selectedTransmission == trans;
              final chipBg = isDark ? const Color(0xFF2B313A) : const Color(0xFFF1F5F9);
              final unselectedText = isDark ? Colors.grey[300] : AppColors.textPrimary;

              return ChoiceChip(
                label: Text(trans),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: chipBg,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.border),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : unselectedText,
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
          isDark: isDark,
          title: 'Preferred City',
          subtitle: _selectedCity,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            dropdownColor: isDark ? const Color(0xFF242930) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2329) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border,
                ),
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
              backgroundColor: AppColors.accent,
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
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cardBg = isDark ? const Color(0xFF1F2329) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cardBorder),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
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
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.accent,
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
