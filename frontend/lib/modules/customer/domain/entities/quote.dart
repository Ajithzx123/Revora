class Quote {
  final String id;
  final String requirementId;
  final String dealerId;
  final String dealerName;
  final String dealerCity;
  final double dealerRating;
  final String carTitle;
  final int carYear;
  final int carMileage;
  final String carFuel;
  final double quotedPrice;
  final String carImageUrl;
  final String comment;
  final String status;
  final int matchPercentage;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.requirementId,
    required this.dealerId,
    required this.dealerName,
    required this.dealerCity,
    this.dealerRating = 4.5,
    required this.carTitle,
    required this.carYear,
    required this.carMileage,
    required this.carFuel,
    required this.quotedPrice,
    required this.carImageUrl,
    this.comment = '',
    this.status = 'pending',
    this.matchPercentage = 90,
    required this.createdAt,
  });

  String get formattedPrice => '₹${(quotedPrice / 100000).toStringAsFixed(2)} Lakh';
}
