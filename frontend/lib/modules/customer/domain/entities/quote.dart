import '../../../../core/network/media_url.dart';

/// One counter-offer in a price negotiation (at most 5 per quote).
class QuoteRound {
  final String id;
  final int roundNo;
  final String by; // CUSTOMER or DEALER
  final int price;
  final String? note;
  final String status; // OPEN, AGREED, DECLINED, COUNTERED, SUPERSEDED, EXPIRED
  final DateTime validUntil;

  const QuoteRound({
    required this.id,
    required this.roundNo,
    required this.by,
    required this.price,
    this.note,
    required this.status,
    required this.validUntil,
  });

  bool get isOpen => status == 'OPEN' && validUntil.isAfter(DateTime.now());

  factory QuoteRound.fromJson(Map<String, dynamic> j) => QuoteRound(
        id: j['id'] as String,
        roundNo: j['round_no'] as int,
        by: j['by'] as String,
        price: j['price'] as int,
        note: j['note'] as String?,
        status: j['status'] as String,
        validUntil: parseUtc(j['valid_until'] as String),
      );
}

/// The API sends UTC without a zone suffix.
DateTime parseUtc(String raw) {
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw);
  return DateTime.parse(hasZone ? raw : '${raw}Z').toLocal();
}

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

  /// IN_STOCK, ALTERNATIVE (another model) or SOURCED (not in stock yet).
  final String kind;
  final int revision;
  final DateTime? validUntil;
  final int? deliveryDays;
  final int? warrantyMonths;
  final String? statusReason;
  final List<QuoteRound> rounds;

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
    this.status = 'PENDING',
    this.matchPercentage = 90,
    required this.createdAt,
    this.kind = 'IN_STOCK',
    this.revision = 1,
    this.validUntil,
    this.deliveryDays,
    this.warrantyMonths,
    this.statusReason,
    this.rounds = const [],
  });

  String get formattedPrice => '₹${(quotedPrice / 100000).toStringAsFixed(2)} Lakh';

  int get price => quotedPrice.round();

  bool get isLive => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';

  QuoteRound? get openRound {
    for (final r in rounds.reversed) {
      if (r.isOpen) return r;
    }
    return null;
  }

  String get kindLabel {
    switch (kind) {
      case 'ALTERNATIVE':
        return 'Different model';
      case 'SOURCED':
        return 'Will be sourced for you';
      default:
        return 'In stock';
    }
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Declined by you';
      case 'NOT_SELECTED':
        return 'Not selected';
      case 'WITHDRAWN':
        return 'Withdrawn by dealer';
      case 'EXPIRED':
        return 'Expired';
      case 'UNAVAILABLE':
        return 'Car sold';
      case 'REQUOTE_REQUESTED':
        return 'Dealer updating price';
      case 'CLOSED_BY_CUSTOMER':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  /// "Valid for 2d" / "Expires in 5h"; null when there is no deadline or it has passed.
  String? get validityLabel {
    final until = validUntil;
    if (until == null || !isLive) return null;
    final left = until.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    if (left.inHours >= 24) return 'Valid for ${left.inDays}d';
    if (left.inHours >= 1) return 'Expires in ${left.inHours}h';
    return 'Expires in ${left.inMinutes.clamp(1, 59)}m';
  }

  Quote copyWith({String? status, double? quotedPrice, String? statusReason, List<QuoteRound>? rounds, int? revision}) => Quote(
        id: id,
        requirementId: requirementId,
        dealerId: dealerId,
        dealerName: dealerName,
        dealerCity: dealerCity,
        dealerRating: dealerRating,
        carTitle: carTitle,
        carYear: carYear,
        carMileage: carMileage,
        carFuel: carFuel,
        quotedPrice: quotedPrice ?? this.quotedPrice,
        carImageUrl: carImageUrl,
        comment: comment,
        status: status ?? this.status,
        matchPercentage: matchPercentage,
        createdAt: createdAt,
        kind: kind,
        revision: revision ?? this.revision,
        validUntil: validUntil,
        deliveryDays: deliveryDays,
        warrantyMonths: warrantyMonths,
        statusReason: statusReason ?? this.statusReason,
        rounds: rounds ?? this.rounds,
      );

  factory Quote.fromJson(Map<String, dynamic> j) {
    final image = j['vehicle_image_url'] as String?;
    return Quote(
      id: j['id'] as String,
      requirementId: j['requirement_id'] as String,
      dealerId: j['dealer_id'] as String,
      dealerName: (j['dealer_name'] as String?) ?? 'Dealer',
      dealerCity: '',
      dealerRating: ((j['dealer_rating'] as num?) ?? 0).toDouble(),
      carTitle: (j['vehicle_title'] as String?) ?? 'Car to be sourced',
      carYear: (j['vehicle_year'] as int?) ?? 0,
      carMileage: (j['vehicle_km'] as int?) ?? 0,
      carFuel: (j['vehicle_fuel'] as String?) ?? '',
      quotedPrice: (j['quoted_price'] as num).toDouble(),
      carImageUrl: image == null ? '' : resolveMediaUrl(image),
      comment: (j['message'] as String?) ?? '',
      status: (j['status'] as String?) ?? 'PENDING',
      matchPercentage: 0,
      createdAt: parseUtc(j['created_at'] as String),
      kind: (j['kind'] as String?) ?? 'IN_STOCK',
      revision: (j['revision'] as int?) ?? 1,
      validUntil: j['valid_until'] == null ? null : parseUtc(j['valid_until'] as String),
      deliveryDays: j['delivery_days'] as int?,
      warrantyMonths: j['warranty_months'] as int?,
      statusReason: j['status_reason'] as String?,
      rounds: [for (final r in (j['rounds'] as List? ?? const [])) QuoteRound.fromJson(r as Map<String, dynamic>)],
    );
  }
}
