import '../../../customer/domain/entities/sell_offer.dart';

/// A dealer's own offer plus a summary of the listing. The seller's contact is only present
/// once the offer has been accepted.
class MyOffer {
  final SellOffer offer;
  final String listingTitle;
  final String listingCity;
  final String listingStatus;
  final String sellerFirstName;
  final String? sellerName;
  final String? sellerPhone;

  const MyOffer({
    required this.offer,
    required this.listingTitle,
    this.listingCity = '',
    this.listingStatus = '',
    this.sellerFirstName = 'Seller',
    this.sellerName,
    this.sellerPhone,
  });

  factory MyOffer.fromJson(Map<String, dynamic> j) => MyOffer(
    offer: SellOffer.fromJson(j),
    listingTitle: (j['listing_title'] as String?) ?? '',
    listingCity: (j['listing_city'] as String?) ?? '',
    listingStatus: (j['listing_status'] as String?) ?? '',
    sellerFirstName: (j['seller_first_name'] as String?) ?? 'Seller',
    sellerName: j['seller_name'] as String?,
    sellerPhone: j['seller_phone'] as String?,
  );
}
