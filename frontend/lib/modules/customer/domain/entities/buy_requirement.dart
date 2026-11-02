/// A buyer's request: what car they want, within what budget, where, and how soon.
class BuyRequirement {
  final String id;
  final String make;

  /// Empty means "any model of this make".
  final String model;
  final int minYear;
  final int maxYear;
  final double minBudget;
  final double maxBudget;

  /// "Any" when the buyer did not pick one.
  final String fuelType;
  final String transmission;
  final String preferredCity;

  /// Lower-case: open, paused, cancelled, expired, quote_accepted, in_transaction,
  /// completed. (Demo data also uses "active", which means open.)
  final String status;
  final int quotesReceived;
  final DateTime createdAt;

  final String? variant;
  final String? bodyType;
  final int? maxKm;
  final int? maxOwners;
  final int radiusKm;
  final String urgency;
  final bool needsFinance;
  final bool hasExchange;

  /// Field names the buyer marked as must-haves (the rest are preferences).
  final List<String> mustHave;
  final String? notes;
  final DateTime? expiresAt;

  const BuyRequirement({
    required this.id,
    required this.make,
    required this.model,
    required this.minYear,
    required this.maxYear,
    required this.minBudget,
    required this.maxBudget,
    required this.fuelType,
    required this.transmission,
    required this.preferredCity,
    this.status = 'open',
    this.quotesReceived = 0,
    required this.createdAt,
    this.variant,
    this.bodyType,
    this.maxKm,
    this.maxOwners,
    this.radiusKm = 50,
    this.urgency = 'WITHIN_2_WEEKS',
    this.needsFinance = false,
    this.hasExchange = false,
    this.mustHave = const [],
    this.notes,
    this.expiresAt,
  });

  bool get isOpen => status == 'open' || status == 'active';
  bool get isPaused => status == 'paused';

  /// Open or paused: the buyer can still change it.
  bool get isEditable => isOpen || isPaused;

  String get title {
    final car = model.isEmpty ? make : '$make $model';
    final openEnded = maxYear > DateTime.now().year;
    return openEnded ? '$minYear+ $car' : '$minYear-$maxYear $car';
  }

  String get budgetRange =>
      '₹${(minBudget / 100000).toStringAsFixed(1)} - ${(maxBudget / 100000).toStringAsFixed(1)} Lakh';

  String get statusLabel {
    switch (status) {
      case 'open':
      case 'active':
        return 'Open';
      case 'paused':
        return 'Paused';
      case 'cancelled':
        return 'Closed';
      case 'expired':
        return 'Expired';
      case 'quote_accepted':
        return 'Deal in progress';
      case 'in_transaction':
        return 'Deal in progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

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

  factory BuyRequirement.fromJson(Map<String, dynamic> j) {
    final year = DateTime.now().year;
    return BuyRequirement(
      id: j['id'] as String,
      make: j['make'] as String,
      model: (j['model'] as String?) ?? '',
      variant: j['variant'] as String?,
      minYear: j['year_min'] as int,
      maxYear: (j['year_max'] as int?) ?? year + 1,
      minBudget: ((j['budget_min'] as num?) ?? 0).toDouble(),
      maxBudget: (j['budget_max'] as num).toDouble(),
      fuelType: (j['fuel'] as String?) ?? 'Any',
      transmission: (j['transmission'] as String?) ?? 'Any',
      bodyType: j['body_type'] as String?,
      maxKm: j['max_km'] as int?,
      maxOwners: j['max_owners'] as int?,
      preferredCity: j['city'] as String,
      radiusKm: (j['radius_km'] as int?) ?? 50,
      urgency: (j['urgency'] as String?) ?? 'WITHIN_2_WEEKS',
      needsFinance: (j['needs_finance'] as bool?) ?? false,
      hasExchange: (j['has_exchange'] as bool?) ?? false,
      mustHave: [for (final m in (j['must_have'] as List? ?? const [])) m as String],
      notes: j['notes'] as String?,
      status: ((j['status'] as String?) ?? 'OPEN').toLowerCase(),
      quotesReceived: (j['quote_count'] as int?) ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
      expiresAt: j['expires_at'] == null ? null : DateTime.parse(j['expires_at'] as String),
    );
  }
}
