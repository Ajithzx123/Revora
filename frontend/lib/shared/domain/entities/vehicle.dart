class Vehicle {
  final String id;
  final String title;
  final String make;
  final String model;
  final int year;
  final double price;
  final String fuelType;
  final String transmission;
  final int mileage;
  final String city;
  final String imageUrl;
  final String? dealerId;
  final String? dealerName;
  final bool isVerified;
  final String status;

  const Vehicle({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.fuelType,
    required this.transmission,
    required this.mileage,
    required this.city,
    required this.imageUrl,
    this.dealerId,
    this.dealerName,
    this.isVerified = false,
    this.status = 'active',
  });

  Vehicle copyWith({
    String? id,
    String? title,
    String? make,
    String? model,
    int? year,
    double? price,
    String? fuelType,
    String? transmission,
    int? mileage,
    String? city,
    String? imageUrl,
    String? dealerId,
    String? dealerName,
    bool? isVerified,
    String? status,
  }) {
    return Vehicle(
      id: id ?? this.id,
      title: title ?? this.title,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      price: price ?? this.price,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      mileage: mileage ?? this.mileage,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
    );
  }
}
