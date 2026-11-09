import '../../../customer/domain/entities/sell_post.dart';

/// A sell listing the dealer was matched to. It carries the car and why it matched, and never
/// the seller's name or phone: contact is released only after the seller accepts an offer.
class SellLead {
  final SellPost listing;
  final int matchScore;
  final List<String> matchReasons;

  /// The dealer's own offer on this listing, if any (PENDING, ACCEPTED, ...).
  final String? myOfferStatus;

  const SellLead({
    required this.listing,
    this.matchScore = 0,
    this.matchReasons = const [],
    this.myOfferStatus,
  });

  factory SellLead.fromJson(Map<String, dynamic> j) => SellLead(
    listing: SellPost.fromJson(j),
    matchScore: (j['match_score'] as int?) ?? 0,
    matchReasons: [
      for (final r in (j['match_reasons'] as List? ?? const [])) r as String,
    ],
    myOfferStatus: j['my_offer_status'] as String?,
  );

  String get id => listing.id;
}
