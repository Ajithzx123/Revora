/// One counter-offer in a price negotiation on an offer (at most 5 per offer).
class OfferRound {
  final String id;
  final int roundNo;
  final String by; // SELLER or DEALER
  final int price;
  final String? note;
  final String status; // OPEN, AGREED, DECLINED, COUNTERED, SUPERSEDED, EXPIRED
  final DateTime validUntil;

  const OfferRound({
    required this.id,
    required this.roundNo,
    required this.by,
    required this.price,
    this.note,
    required this.status,
    required this.validUntil,
  });

  bool get isOpen => status == 'OPEN' && validUntil.isAfter(DateTime.now());

  factory OfferRound.fromJson(Map<String, dynamic> j) => OfferRound(
    id: j['id'] as String,
    roundNo: j['round_no'] as int,
    by: j['by'] as String,
    price: j['price'] as int,
    note: j['note'] as String?,
    status: j['status'] as String,
    validUntil: _utc(j['valid_until'] as String),
  );
}

/// A dealer's purchase offer on a sell listing, as the seller sees it.
class SellOffer {
  final String id;
  final String dealerId;
  final String dealerName;
  final double? dealerRating;
  final String listingId;
  final int price; // rupees
  final String? message;

  /// PENDING (live), ACCEPTED, REJECTED, NOT_SELECTED, WITHDRAWN, EXPIRED, VOID_ADMIN.
  final String status;
  final String? statusReason;
  final int revision;
  final DateTime? validUntil;
  final bool inspectionRequired;
  final int? pickupDays;
  final bool loanSettlementRequired;
  final DateTime createdAt;
  final List<OfferRound> rounds;

  /// The inspection stage after the seller accepts: null (no final offer yet), SUBMITTED
  /// (waiting for the seller), ACCEPTED, DECLINED.
  final String? finalStatus;
  final int? finalPrice;
  final double? finalDropPercent;
  final String? finalReasonCode;
  final String? finalReasonNote;
  final List<String> finalEvidence;

  const SellOffer({
    required this.id,
    required this.dealerId,
    required this.dealerName,
    this.dealerRating,
    required this.listingId,
    required this.price,
    this.message,
    this.status = 'PENDING',
    this.statusReason,
    this.revision = 1,
    this.validUntil,
    this.inspectionRequired = true,
    this.pickupDays,
    this.loanSettlementRequired = false,
    required this.createdAt,
    this.rounds = const [],
    this.finalStatus,
    this.finalPrice,
    this.finalDropPercent,
    this.finalReasonCode,
    this.finalReasonNote,
    this.finalEvidence = const [],
  });

  factory SellOffer.fromJson(Map<String, dynamic> j) => SellOffer(
    id: j['id'] as String,
    dealerId: j['dealer_id'] as String,
    dealerName: (j['dealer_name'] as String?) ?? 'Dealer',
    dealerRating: (j['dealer_rating'] as num?)?.toDouble(),
    listingId: j['sell_listing_id'] as String,
    price: j['offered_price'] as int,
    message: j['message'] as String?,
    status: j['status'] as String,
    statusReason: j['status_reason'] as String?,
    revision: (j['revision'] as int?) ?? 1,
    validUntil: j['valid_until'] == null
        ? null
        : _utc(j['valid_until'] as String),
    inspectionRequired: (j['inspection_required'] as bool?) ?? true,
    pickupDays: j['pickup_days'] as int?,
    loanSettlementRequired: (j['loan_settlement_required'] as bool?) ?? false,
    createdAt: _utc(j['created_at'] as String),
    rounds: [
      for (final r in (j['rounds'] as List? ?? const []))
        OfferRound.fromJson(r as Map<String, dynamic>),
    ],
    finalStatus: j['final_status'] as String?,
    finalPrice: j['final_price'] as int?,
    finalDropPercent: (j['final_drop_percent'] as num?)?.toDouble(),
    finalReasonCode: j['final_reason_code'] as String?,
    finalReasonNote: j['final_reason_note'] as String?,
    finalEvidence: [
      for (final e in (j['final_evidence'] as List? ?? const [])) e as String,
    ],
  );

  bool get isLive => status == 'PENDING';

  /// The counter-offer still waiting for an answer, if any.
  OfferRound? get openRound {
    for (final r in rounds) {
      if (r.isOpen) return r;
    }
    return null;
  }

  /// Accepted and subject to inspection, with no final price yet.
  bool get awaitingInspection =>
      status == 'ACCEPTED' && inspectionRequired && finalStatus == null;

  /// The dealer lowered the price after inspecting; the seller has not answered.
  bool get finalAwaitingSeller => finalStatus == 'SUBMITTED';

  SellOffer copyWith({
    String? status,
    String? statusReason,
    int? price,
    List<OfferRound>? rounds,
    String? finalStatus,
    int? finalPrice,
    double? finalDropPercent,
    String? finalReasonCode,
    String? finalReasonNote,
    List<String>? finalEvidence,
  }) => SellOffer(
    id: id,
    dealerId: dealerId,
    dealerName: dealerName,
    dealerRating: dealerRating,
    listingId: listingId,
    price: price ?? this.price,
    message: message,
    status: status ?? this.status,
    statusReason: statusReason ?? this.statusReason,
    revision: revision,
    validUntil: validUntil,
    inspectionRequired: inspectionRequired,
    pickupDays: pickupDays,
    loanSettlementRequired: loanSettlementRequired,
    createdAt: createdAt,
    rounds: rounds ?? this.rounds,
    finalStatus: finalStatus ?? this.finalStatus,
    finalPrice: finalPrice ?? this.finalPrice,
    finalDropPercent: finalDropPercent ?? this.finalDropPercent,
    finalReasonCode: finalReasonCode ?? this.finalReasonCode,
    finalReasonNote: finalReasonNote ?? this.finalReasonNote,
    finalEvidence: finalEvidence ?? this.finalEvidence,
  );
}

DateTime _utc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();
