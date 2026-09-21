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
  });

  String get title => '$minYear-$maxYear $make $model';
  String get budgetRange => '₹${(minBudget / 100000).toStringAsFixed(1)} - ${(maxBudget / 100000).toStringAsFixed(1)} Lakh';
}
