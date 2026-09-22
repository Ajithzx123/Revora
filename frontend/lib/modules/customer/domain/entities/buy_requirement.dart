class BuyRequirement {
  final String id;
  final String make;
  final String model;
  final int minYear;
  final int maxYear;
  final double minBudget;
  final double maxBudget;
  final String fuelType;
  final String transmission;
  final String preferredCity;
  final String? variant;
  final String status;
  final int quotesReceived;
  final DateTime createdAt;

  const BuyRequirement({
    required this.id,
    required this.make,
    required this.model,
    this.variant,
    required this.minYear,
    required this.maxYear,
    required this.minBudget,
    required this.maxBudget,
    required this.fuelType,
    required this.transmission,
    required this.preferredCity,
    this.status = 'active',
    this.quotesReceived = 0,
    required this.createdAt,
  });

  String get title => variant != null && variant!.isNotEmpty
      ? '$minYear-$maxYear $make $model ($variant)'
      : '$minYear-$maxYear $make $model';
  String get budgetRange => '₹${(minBudget / 100000).toStringAsFixed(1)} - ${(maxBudget / 100000).toStringAsFixed(1)} Lakh';
}
