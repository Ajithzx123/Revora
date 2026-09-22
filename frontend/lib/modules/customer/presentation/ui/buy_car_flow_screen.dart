import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/buy_requirement.dart';
import '../providers/car_selection_provider.dart';
import '../providers/customer_providers.dart';
import 'widgets/buy_flow/brand_selection_step.dart';
import 'widgets/buy_flow/model_selection_step.dart';
import 'widgets/buy_flow/variant_selection_step.dart';
import 'widgets/buy_flow/requirement_details_step.dart';
import 'widgets/buy_flow/review_submit_step.dart';
import 'widgets/buy_flow/selected_summary_chip.dart';
import 'widgets/buy_flow/step_reveal_wrapper.dart';

class BuyCarFlowScreen extends ConsumerStatefulWidget {
  const BuyCarFlowScreen({super.key});

  @override
  ConsumerState<BuyCarFlowScreen> createState() => _BuyCarFlowScreenState();
}

class _BuyCarFlowScreenState extends ConsumerState<BuyCarFlowScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carSelectionProvider);
    final notifier = ref.read(carSelectionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF131518) : AppColors.background;
    final appBarBg = isDark ? const Color(0xFF131518) : Colors.white;
    final backBtnBg = isDark ? const Color(0xFF22262C) : const Color(0xFFF1F5F9);
    final backIconColor = isDark ? Colors.white : AppColors.primary;
    final appBarTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: backBtnBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.border,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 15, color: backIconColor),
              onPressed: () {
                if (state.currentStep == BuyWizardStep.brand) {
                  context.pop();
                } else if (state.currentStep == BuyWizardStep.model) {
                  notifier.goToStep(BuyWizardStep.brand);
                } else if (state.currentStep == BuyWizardStep.variant) {
                  notifier.goToStep(BuyWizardStep.model);
                } else if (state.currentStep == BuyWizardStep.details) {
                  notifier.goToStep(BuyWizardStep.variant);
                } else if (state.currentStep == BuyWizardStep.review) {
                  notifier.goToStep(BuyWizardStep.details);
                }
              },
            ),
          ),
        ),
        title: Text(
          _getAppBarTitle(state.currentStep),
          style: TextStyle(
            color: appBarTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          // Theme Toggle Icon
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Progress Indicator
                _buildProgressIndicator(state.currentStep, isDark),
                const SizedBox(height: AppSpacing.lg),

                // 2. Animated locked-in summary chips at the top
                if (state.selectedBrand != null)
                  SelectedSummaryChip(
                    label: 'Brand',
                    value: state.selectedBrand!,
                    icon: Icons.directions_car_filled,
                    onEdit: () {
                      notifier.goToStep(BuyWizardStep.brand);
                      _scrollToTop();
                    },
                  ),

                if (state.selectedModel != null &&
                    state.currentStep.index >= BuyWizardStep.variant.index)
                  SelectedSummaryChip(
                    label: 'Model',
                    value: state.selectedModel!,
                    icon: Icons.model_training,
                    onEdit: () {
                      notifier.goToStep(BuyWizardStep.model);
                      _scrollToTop();
                    },
                  ),

                if (state.selectedVariant != null &&
                    state.currentStep.index >= BuyWizardStep.details.index)
                  SelectedSummaryChip(
                    label: 'Variant',
                    value: state.selectedVariant!,
                    icon: Icons.tune,
                    onEdit: () {
                      notifier.goToStep(BuyWizardStep.variant);
                      _scrollToTop();
                    },
                  ),

                if (state.currentStep == BuyWizardStep.review)
                  SelectedSummaryChip(
                    label: 'Preferences',
                    value:
                        '${state.minYear}-${state.maxYear} • ₹${(state.minBudget / 100000).toStringAsFixed(0)}-${(state.maxBudget / 100000).toStringAsFixed(0)}L • ${state.fuelType}',
                    icon: Icons.settings,
                    onEdit: () {
                      notifier.goToStep(BuyWizardStep.details);
                      _scrollToTop();
                    },
                  ),

                const SizedBox(height: AppSpacing.sm),

                // 3. Current active step view
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: _buildCurrentStep(state, notifier),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(BuyWizardStep step) {
    switch (step) {
      case BuyWizardStep.brand:
        return 'All Brands';
      case BuyWizardStep.model:
        return 'Choose Model';
      case BuyWizardStep.variant:
        return 'Choose Variant';
      case BuyWizardStep.details:
        return 'Specify Details';
      case BuyWizardStep.review:
        return 'Review Requirement';
    }
  }

  Widget _buildProgressIndicator(BuyWizardStep currentStep, bool isDark) {
    const steps = BuyWizardStep.values;
    final progress = (currentStep.index + 1) / steps.length;
    final progressBg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.grey[400] : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP ${currentStep.index + 1} OF ${steps.length}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: progressBg,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(
    CarSelectionState state,
    CarSelectionNotifier notifier,
  ) {
    switch (state.currentStep) {
      case BuyWizardStep.brand:
        return StepRevealWrapper(
          key: const ValueKey('brand_step'),
          child: BrandSelectionStep(
            onBrandSelected: (brand) {
              notifier.selectBrand(brand);
              _scrollToTop();
            },
          ),
        );

      case BuyWizardStep.model:
        return StepRevealWrapper(
          key: const ValueKey('model_step'),
          child: ModelSelectionStep(
            brand: state.selectedBrand!,
            onModelSelected: (model) {
              notifier.selectModel(model);
              _scrollToTop();
            },
          ),
        );

      case BuyWizardStep.variant:
        return StepRevealWrapper(
          key: const ValueKey('variant_step'),
          child: VariantSelectionStep(
            brand: state.selectedBrand!,
            model: state.selectedModel!,
            onVariantSelected: (variant) {
              notifier.selectVariant(variant);
              _scrollToTop();
            },
          ),
        );

      case BuyWizardStep.details:
        return StepRevealWrapper(
          key: const ValueKey('details_step'),
          child: RequirementDetailsStep(
            state: state,
            onUpdate: notifier.updateDetails,
            onContinue: () {
              notifier.proceedToReview();
              _scrollToTop();
            },
          ),
        );

      case BuyWizardStep.review:
        return StepRevealWrapper(
          key: const ValueKey('review_step'),
          child: ReviewSubmitStep(
            state: state,
            onEditBrand: () => notifier.goToStep(BuyWizardStep.brand),
            onEditModel: () => notifier.goToStep(BuyWizardStep.model),
            onEditVariant: () => notifier.goToStep(BuyWizardStep.variant),
            onEditDetails: () => notifier.goToStep(BuyWizardStep.details),
            onSubmit: () {
              final newReq = BuyRequirement(
                id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                make: state.selectedBrand ?? 'Car',
                model: state.selectedModel ?? 'Model',
                variant: state.selectedVariant,
                minYear: state.minYear,
                maxYear: state.maxYear,
                minBudget: state.minBudget,
                maxBudget: state.maxBudget,
                fuelType: state.fuelType,
                transmission: state.transmission,
                preferredCity: state.preferredCity,
                status: 'active',
                quotesReceived: 0,
                createdAt: DateTime.now(),
              );

              final repo = ref.read(customerRepositoryProvider);
              repo.addRequirement(newReq);

              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Requirement for ${newReq.make} ${newReq.model} posted to dealers!',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
    }
  }
}
