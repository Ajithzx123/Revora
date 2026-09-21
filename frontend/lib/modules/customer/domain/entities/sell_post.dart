class SellPost {
  final String id;
  final String make;
  final String model;
  final int year;
  final String variant;
  final int mileage;
  final String fuelType;
  final String transmission;
  final double expectedPrice;
  final String city;
  final String status;
  final int offersCount;
  final List<String> imageUrls;
  final DateTime createdAt;

  const SellPost({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.variant,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.expectedPrice,
    required this.city,
    this.status = 'active',
    this.offersCount = 0,
    required this.imageUrls,
    required this.createdAt,
  });

  String get title => '$year $make $model $variant';
  String get formattedPrice => '₹${(expectedPrice / 100000).toStringAsFixed(2)} Lakh';
}
