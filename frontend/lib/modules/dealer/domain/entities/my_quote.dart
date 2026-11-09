import '../../../customer/domain/entities/quote.dart';

/// A dealer's own quote plus a summary of the request it answers. The buyer's contact
/// is only present once the quote has been accepted.
class MyQuote {
  final Quote quote;
  final String requestTitle;
  final String requestCity;
  final String requestStatus;
  final String buyerFirstName;
  final String? buyerName;
  final String? buyerPhone;

  const MyQuote({
    required this.quote,
    required this.requestTitle,
    required this.requestCity,
    this.requestStatus = '',
    this.buyerFirstName = 'Buyer',
    this.buyerName,
    this.buyerPhone,
  });

  factory MyQuote.fromJson(Map<String, dynamic> j) => MyQuote(
    quote: Quote.fromJson(j),
    requestTitle: (j['request_title'] as String?) ?? '',
    requestCity: (j['request_city'] as String?) ?? '',
    requestStatus: (j['request_status'] as String?) ?? '',
    buyerFirstName: (j['buyer_first_name'] as String?) ?? 'Buyer',
    buyerName: j['buyer_name'] as String?,
    buyerPhone: j['buyer_phone'] as String?,
  );
}
