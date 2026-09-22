import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BuyWizardStep {
  brand,
  model,
  variant,
  details,
  review,
}

class CarSelectionState {
  final String? selectedBrand;
  final String? selectedModel;
  final String? selectedVariant;
  final BuyWizardStep currentStep;
  final String brandSearchQuery;

  // Details fields
  final int minYear;
  final int maxYear;
  final double minBudget;
  final double maxBudget;
  final String fuelType;
  final String transmission;
  final String preferredCity;

  const CarSelectionState({
    this.selectedBrand,
    this.selectedModel,
    this.selectedVariant,
    this.currentStep = BuyWizardStep.brand,
    this.brandSearchQuery = '',
    this.minYear = 2020,
    this.maxYear = 2024,
    this.minBudget = 800000,
    this.maxBudget = 1600000,
    this.fuelType = 'Petrol',
    this.transmission = 'Automatic',
    this.preferredCity = 'Bengaluru',
  });

  CarSelectionState copyWith({
    String? selectedBrand,
    String? selectedModel,
    String? selectedVariant,
    BuyWizardStep? currentStep,
    String? brandSearchQuery,
    int? minYear,
    int? maxYear,
    double? minBudget,
    double? maxBudget,
    String? fuelType,
    String? transmission,
    String? preferredCity,
    bool clearModel = false,
    bool clearVariant = false,
  }) {
    return CarSelectionState(
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedModel: clearModel ? null : (selectedModel ?? this.selectedModel),
      selectedVariant: clearVariant ? null : (selectedVariant ?? this.selectedVariant),
      currentStep: currentStep ?? this.currentStep,
      brandSearchQuery: brandSearchQuery ?? this.brandSearchQuery,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      preferredCity: preferredCity ?? this.preferredCity,
    );
  }
}

class CarSelectionNotifier extends StateNotifier<CarSelectionState> {
  CarSelectionNotifier() : super(const CarSelectionState());

  void setSearchQuery(String query) {
    state = state.copyWith(brandSearchQuery: query);
  }

  void selectBrand(String brand) {
    state = state.copyWith(
      selectedBrand: brand,
      clearModel: true,
      clearVariant: true,
      currentStep: BuyWizardStep.model,
    );
  }

  void selectModel(String model) {
    state = state.copyWith(
      selectedModel: model,
      clearVariant: true,
      currentStep: BuyWizardStep.variant,
    );
  }

  void selectVariant(String variant) {
    state = state.copyWith(
      selectedVariant: variant,
      currentStep: BuyWizardStep.details,
    );
  }

  void updateDetails({
    int? minYear,
    int? maxYear,
    double? minBudget,
    double? maxBudget,
    String? fuelType,
    String? transmission,
    String? preferredCity,
  }) {
    state = state.copyWith(
      minYear: minYear,
      maxYear: maxYear,
      minBudget: minBudget,
      maxBudget: maxBudget,
      fuelType: fuelType,
      transmission: transmission,
      preferredCity: preferredCity,
    );
  }

  void proceedToReview() {
    state = state.copyWith(currentStep: BuyWizardStep.review);
  }

  void goToStep(BuyWizardStep step) {
    state = state.copyWith(currentStep: step);
  }

  void reset() {
    state = const CarSelectionState();
  }
}

final carSelectionProvider =
    StateNotifierProvider.autoDispose<CarSelectionNotifier, CarSelectionState>((ref) {
  return CarSelectionNotifier();
});
