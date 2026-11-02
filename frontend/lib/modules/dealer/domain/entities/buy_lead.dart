class BuyLead {
  final String id;
  final String customerName;
  final String customerCity;
  final String make;
  final String model;
  final int minYear;
  final int maxYear;
  final double minBudget;
  final double maxBudget;
  final String fuelType;
  final String transmission;
  final int matchPercentage;
  final String status;
  final int quotesCount;
  final DateTime createdAt;

  final String urgency;
  final bool needsFinance;
  final bool hasExchange;
  final List<String> mustHave;
  final String? bodyType;
  final String? notes;
  final int radiusKm;

  const BuyLead({
    required this.id,
    required this.customerName,
    required this.customerCity,
    required this.make,
    required this.model,
    required this.minYear,
    required this.maxYear,
    required this.minBudget,
    required this.maxBudget,
    required this.fuelType,
    required this.transmission,
    required this.matchPercentage,
    this.status = 'active',
    this.quotesCount = 0,
    required this.createdAt,
    this.urgency = 'WITHIN_2_WEEKS',
    this.needsFinance = false,
    this.hasExchange = false,
    this.mustHave = const [],
    this.bodyType,
    this.notes,
    this.radiusKm = 50,
  });

  String get urgencyLabel {
    switch (urgency) {
      case 'NOW':
        return 'Needs it now';
      case 'WITHIN_60_DAYS':
        return 'In 30-60 days';
      default:
        return 'In 1-2 weeks';
    }
  }

  /// A lead from the API. Buyers arrive as first name + city only.
  factory BuyLead.fromJson(Map<String, dynamic> j) {
    final year = DateTime.now().year;
    return BuyLead(
      id: j['id'] as String,
      customerName: (j['buyer_first_name'] as String?) ?? 'Buyer',
      customerCity: j['city'] as String,
      make: j['make'] as String,
      model: (j['model'] as String?) ?? '',
      minYear: j['year_min'] as int,
      maxYear: (j['year_max'] as int?) ?? year + 1,
      minBudget: ((j['budget_min'] as num?) ?? 0).toDouble(),
      maxBudget: (j['budget_max'] as num).toDouble(),
      fuelType: (j['fuel'] as String?) ?? 'Any',
      transmission: (j['transmission'] as String?) ?? 'Any',
      matchPercentage: 0, // matching arrives in S3; 0 hides the badge
      quotesCount: (j['quote_count'] as int?) ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
      urgency: (j['urgency'] as String?) ?? 'WITHIN_2_WEEKS',
      needsFinance: (j['needs_finance'] as bool?) ?? false,
      hasExchange: (j['has_exchange'] as bool?) ?? false,
      mustHave: [for (final m in (j['must_have'] as List? ?? const [])) m as String],
      bodyType: j['body_type'] as String?,
      notes: j['notes'] as String?,
      radiusKm: (j['radius_km'] as int?) ?? 50,
    );
  }

  String get title {
    final car = model.isEmpty ? make : '$make $model';
    return maxYear > DateTime.now().year ? '$minYear+ $car' : '$minYear-$maxYear $car';
  }
  String get budgetRange => '₹${(minBudget / 100000).toStringAsFixed(1)} - ${(maxBudget / 100000).toStringAsFixed(1)} Lakh';
}
