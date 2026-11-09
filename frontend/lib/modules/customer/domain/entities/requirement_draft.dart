import 'buy_requirement.dart';

/// What the buyer fills in on the form. Becomes the request body on create and edit.
class RequirementDraft {
  String? make;
  String? model; // null = any model
  int yearMin;
  int? yearMax; // null = newest available
  int budgetMin;
  int budgetMax;
  String? fuel; // null = any
  String? transmission;
  String? bodyType;
  int? maxKm;
  int? maxOwners;
  String? city;
  int radiusKm;
  String urgency;
  bool needsFinance;
  bool hasExchange;
  Set<String> mustHave;
  String? notes;

  RequirementDraft({
    this.make,
    this.model,
    int? yearMin,
    this.yearMax,
    this.budgetMin = 0,
    this.budgetMax = 1000000,
    this.fuel,
    this.transmission,
    this.bodyType,
    this.maxKm,
    this.maxOwners,
    this.city,
    this.radiusKm = 50,
    this.urgency = 'WITHIN_2_WEEKS',
    this.needsFinance = false,
    this.hasExchange = false,
    Set<String>? mustHave,
    this.notes,
  }) : yearMin = yearMin ?? DateTime.now().year - 5,
       mustHave = mustHave ?? <String>{};

  factory RequirementDraft.from(BuyRequirement r) => RequirementDraft(
    make: r.make,
    model: r.model.isEmpty ? null : r.model,
    yearMin: r.minYear,
    yearMax: r.maxYear > DateTime.now().year ? null : r.maxYear,
    budgetMin: r.minBudget.round(),
    budgetMax: r.maxBudget.round(),
    fuel: r.fuelType == 'Any' ? null : r.fuelType,
    transmission: r.transmission == 'Any' ? null : r.transmission,
    bodyType: r.bodyType,
    maxKm: r.maxKm,
    maxOwners: r.maxOwners,
    city: r.preferredCity,
    radiusKm: r.radiusKm,
    urgency: r.urgency,
    needsFinance: r.needsFinance,
    hasExchange: r.hasExchange,
    mustHave: {...r.mustHave},
    notes: r.notes,
  );

  /// Every field is sent, nulls included, so an edit can clear an optional field.
  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year_min': yearMin,
    'year_max': yearMax,
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'fuel': fuel,
    'transmission': transmission,
    'body_type': bodyType,
    'max_km': maxKm,
    'max_owners': maxOwners,
    'city': city,
    'radius_km': radiusKm,
    'urgency': urgency,
    'needs_finance': needsFinance,
    'has_exchange': hasExchange,
    'must_have': mustHave.toList()..sort(),
    'notes': (notes ?? '').trim().isEmpty ? null : notes!.trim(),
  };
}
