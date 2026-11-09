/// A car the customer has listed for sale (the backend's sell listing).
class SellPost {
  final String id;
  final String make;
  final String model;
  final int year;
  final String variant;
  final int mileage;
  final String fuelType;
  final String transmission;
  final int expectedPrice; // rupees
  final String city;

  /// ACTIVE (open for offers), OFFER_ACCEPTED, SOLD, CLOSED, EXPIRED, FROZEN.
  /// Older demo data uses lower-case words; the card styling copes with both.
  final String status;
  final String? statusReason;
  final int offersCount;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int owners;
  final String? color;
  final String urgency; // URGENT, NORMAL, MAX_PRICE
  final bool loanOutstanding;
  final int? loanAmount;
  final int? challansAmount;
  final bool? insuranceValid;
  final String? description;
  final DateTime? expiresAt;

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
    this.status = 'ACTIVE',
    this.statusReason,
    this.offersCount = 0,
    required this.imageUrls,
    required this.createdAt,
    this.owners = 1,
    this.color,
    this.urgency = 'NORMAL',
    this.loanOutstanding = false,
    this.loanAmount,
    this.challansAmount,
    this.insuranceValid,
    this.description,
    this.expiresAt,
  });

  factory SellPost.fromJson(Map<String, dynamic> j) => SellPost(
    id: j['id'] as String,
    make: j['make'] as String,
    model: j['model'] as String,
    year: j['year'] as int,
    variant: (j['variant'] as String?) ?? '',
    mileage: j['km'] as int,
    fuelType: j['fuel'] as String,
    transmission: j['transmission'] as String,
    expectedPrice: j['expected_price'] as int,
    city: j['city'] as String,
    status: j['status'] as String,
    statusReason: j['status_reason'] as String?,
    offersCount: (j['offer_count'] as int?) ?? 0,
    imageUrls: [
      for (final i in (j['images'] as List? ?? const [])) i as String,
    ],
    createdAt: _utc(j['created_at'] as String),
    owners: (j['owners'] as int?) ?? 1,
    color: j['color'] as String?,
    urgency: (j['urgency'] as String?) ?? 'NORMAL',
    loanOutstanding: (j['loan_outstanding'] as bool?) ?? false,
    loanAmount: j['loan_amount'] as int?,
    challansAmount: j['challans_amount'] as int?,
    insuranceValid: j['insurance_valid'] as bool?,
    description: j['description'] as String?,
    expiresAt: j['expires_at'] == null ? null : _utc(j['expires_at'] as String),
  );

  /// Offers can still be made and accepted.
  bool get isOpen => status.toUpperCase() == 'ACTIVE';

  String get title =>
      ['$year', make, model, if (variant.isNotEmpty) variant].join(' ');
  String get formattedPrice =>
      '₹${(expectedPrice / 100000).toStringAsFixed(2)} Lakh';
}

/// The API sends UTC timestamps without an offset.
DateTime _utc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();
