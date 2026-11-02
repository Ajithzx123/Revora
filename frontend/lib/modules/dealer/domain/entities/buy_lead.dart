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

  /// 1 exact car in stock, 2 similar car in stock, 3 you can source it (0 = not from matching).
  final int matchTier;
  final List<String> matchReasons;
  final String? matchedVehicleTitle;
  final DateTime? respondBy;

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
    this.matchTier = 0,
    this.matchReasons = const [],
    this.matchedVehicleTitle,
    this.respondBy,
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
      matchPercentage: (j['match_score'] as int?) ?? 0,
      quotesCount: (j['quote_count'] as int?) ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
      urgency: (j['urgency'] as String?) ?? 'WITHIN_2_WEEKS',
      needsFinance: (j['needs_finance'] as bool?) ?? false,
      hasExchange: (j['has_exchange'] as bool?) ?? false,
      mustHave: [for (final m in (j['must_have'] as List? ?? const [])) m as String],
      bodyType: j['body_type'] as String?,
      notes: j['notes'] as String?,
      radiusKm: (j['radius_km'] as int?) ?? 50,
      matchTier: (j['match_tier'] as int?) ?? 0,
      matchReasons: [for (final r in (j['match_reasons'] as List? ?? const [])) r as String],
      matchedVehicleTitle: j['matched_vehicle_title'] as String?,
      respondBy: _utc(j['response_deadline'] as String?),
    );
  }

  /// The API sends UTC without a zone suffix.
  static DateTime? _utc(String? raw) {
    if (raw == null) return null;
    final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw);
    return DateTime.parse(hasZone ? raw : '${raw}Z').toLocal();
  }

  String? get tierLabel {
    switch (matchTier) {
      case 1:
        return 'Exact car in your stock';
      case 2:
        return 'Similar car in your stock';
      case 3:
        return 'You can source this';
      default:
        return null;
    }
  }

  /// "Reply within 5h" style hint; null when there is no deadline or it has passed.
  String? get deadlineLabel {
    final by = respondBy;
    if (by == null) return null;
    final left = by.difference(DateTime.now());
    if (left.isNegative) return null;
    if (left.inHours >= 24) return 'Reply within ${left.inDays}d';
    if (left.inHours >= 1) return 'Reply within ${left.inHours}h';
    return 'Reply within ${left.inMinutes.clamp(1, 59)}m';
  }

  String get title {
    final car = model.isEmpty ? make : '$make $model';
    return maxYear > DateTime.now().year ? '$minYear+ $car' : '$minYear-$maxYear $car';
  }
  String get budgetRange => '₹${(minBudget / 100000).toStringAsFixed(1)} - ${(maxBudget / 100000).toStringAsFixed(1)} Lakh';
}
