class SellLead {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String make;
  final String model;
  final int year;
  final String variant;
  final int mileage;
  final String fuelType;
  final String transmission;
  final double expectedPrice;
  final String imageUrl;
  final String status;
  final int offersCount;
  final DateTime createdAt;

  const SellLead({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerCity,
    required this.make,
    required this.model,
    required this.year,
    required this.variant,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.expectedPrice,
    required this.imageUrl,
    this.status = 'active',
    this.offersCount = 0,
    required this.createdAt,
  });

  String get title => '$year $make $model $variant';
  String get formattedPrice => '₹${(expectedPrice / 100000).toStringAsFixed(2)} Lakh';
}
