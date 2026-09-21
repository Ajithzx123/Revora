class DealerInfo {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String city;
  final String address;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final int totalInventory;
  final int activeDeals;
  final String joinedDate;
  final String logoUrl;

  const DealerInfo({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.city,
    required this.address,
    this.rating = 4.5,
    this.reviewsCount = 0,
    this.isVerified = false,
    this.totalInventory = 0,
    this.activeDeals = 0,
    required this.joinedDate,
    this.logoUrl = '',
  });

  DealerInfo copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? phone,
    String? email,
    String? city,
    String? address,
    double? rating,
    int? reviewsCount,
    bool? isVerified,
    int? totalInventory,
    int? activeDeals,
    String? joinedDate,
    String? logoUrl,
  }) {
    return DealerInfo(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isVerified: isVerified ?? this.isVerified,
      totalInventory: totalInventory ?? this.totalInventory,
      activeDeals: activeDeals ?? this.activeDeals,
      joinedDate: joinedDate ?? this.joinedDate,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
