/// One photo of a vehicle. [url] is absolute and public (the id is the secret).
class VehicleImage {
  final String id;
  final String url;
  const VehicleImage({required this.id, required this.url});
}

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

  // Inventory details (set for a dealer's own stock).
  final String? registrationNo;
  final String? variant;
  final int owners;
  final String? color;
  final String? bodyType;
  final double? minPrice; // private to the dealer
  final String? description;
  final List<VehicleImage> images;

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
    this.registrationNo,
    this.variant,
    this.owners = 1,
    this.color,
    this.bodyType,
    this.minPrice,
    this.description,
    this.images = const [],
  });

  bool get isAvailable => status == 'available' || status == 'active';
  bool get isSold => status == 'sold';

  String get statusLabel {
    switch (status) {
      case 'available':
      case 'active':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'sold':
        return 'Sold';
      default:
        return status;
    }
  }

  /// [resolveUrl] turns the API's relative photo path into an absolute URL.
  factory Vehicle.fromJson(
    Map<String, dynamic> j,
    String Function(String) resolveUrl,
  ) {
    final images = [
      for (final m in (j['images'] as List? ?? const []))
        VehicleImage(
          id: (m as Map)['id'] as String,
          url: resolveUrl(m['url'] as String),
        ),
    ];
    final year = j['year'] as int;
    final variant = j['variant'] as String?;
    return Vehicle(
      id: j['id'] as String,
      title:
          '$year ${j['make']} ${j['model']}${variant == null || variant.isEmpty ? '' : ' $variant'}',
      make: j['make'] as String,
      model: j['model'] as String,
      year: year,
      price: (j['price'] as num).toDouble(),
      fuelType: j['fuel'] as String,
      transmission: j['transmission'] as String,
      mileage: j['km'] as int,
      city: '',
      imageUrl: images.isEmpty ? '' : images.first.url,
      dealerId: j['dealer_id'] as String?,
      status: ((j['status'] as String?) ?? 'AVAILABLE').toLowerCase(),
      registrationNo: j['registration_no'] as String?,
      variant: variant,
      owners: (j['owners'] as int?) ?? 1,
      color: j['color'] as String?,
      bodyType: j['body_type'] as String?,
      minPrice: (j['min_price'] as num?)?.toDouble(),
      description: j['description'] as String?,
      images: images,
    );
  }

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
