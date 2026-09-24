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

  final String? make;
  final String? model;
  final String? variant;
  final String? transmission;
  final String? city;

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
    this.make,
    this.model,
    this.variant,
    this.transmission,
    this.city,
  });

  String get displayMake {
    if (make != null && make!.isNotEmpty) return make!;
    final cleaned = carTitle.replaceFirst(RegExp(r'^\d{4}\s+'), '');
    final parts = cleaned.split(' ');
    return parts.isNotEmpty ? parts.first : 'Car';
  }

  String get displayModel {
    if (model != null && model!.isNotEmpty) return model!;
    final cleaned = carTitle.replaceFirst(RegExp(r'^\d{4}\s+'), '');
    final parts = cleaned.split(' ');
    return parts.length > 1 ? parts[1] : '';
  }

  String get displayVariant {
    if (variant != null && variant!.isNotEmpty) return variant!;
    final cleaned = carTitle.replaceFirst(RegExp(r'^\d{4}\s+'), '');
    final parts = cleaned.split(' ');
    if (parts.length > 2) {
      return parts.sublist(2).join(' ');
    }
    return '$carYear Model';
  }

  String get displayTransmission {
    if (transmission != null && transmission!.isNotEmpty) return transmission!;
    if (carTitle.toUpperCase().contains('MANUAL')) return 'Manual';
    return 'Automatic';
  }

  String get displayCity {
    if (city != null && city!.isNotEmpty) return city!;
    if (dealerCity.contains(',')) {
      return dealerCity.split(',').last.trim();
    }
    if (dealerCity.contains(' ')) {
      return dealerCity.split(' ').last.trim();
    }
    return dealerCity;
  }

  String get formattedPrice => '₹${(quotedPrice / 100000).toStringAsFixed(2)} Lakh';
}
