import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/mock/customer_mock_data.dart';
import '../entities/quote.dart';

/// The buyer's side of a quote: read the offers, negotiate, accept or turn down.
abstract class QuotesRepository {
  Future<List<Quote>> forRequirement(String requirementId);

  /// Fails if the dealer changed the price meanwhile (`expectedPrice` is what the buyer saw).
  Future<Quote> accept(String quoteId, {required int expectedPrice});
  Future<Quote> reject(String quoteId, {String? reason});
  Future<Quote> counter(String quoteId, {required int price, String? note});

  /// Answer the dealer's counter-offer: ACCEPT or DECLINE.
  Future<Quote> respond(String quoteId, String action);
}

class ApiQuotesRepository implements QuotesRepository {
  final Dio _dio;
  ApiQuotesRepository(this._dio);

  Quote _one(Response<dynamic> r) => Quote.fromJson(r.data as Map<String, dynamic>);

  @override
  Future<List<Quote>> forRequirement(String requirementId) async {
    final res = await _dio.get('/requirements/$requirementId/quotes');
    return [for (final j in res.data as List) Quote.fromJson(j as Map<String, dynamic>)];
  }

  @override
  Future<Quote> accept(String quoteId, {required int expectedPrice}) async =>
      _one(await _dio.post('/quotes/$quoteId/accept', data: {'expected_price': expectedPrice}));

  @override
  Future<Quote> reject(String quoteId, {String? reason}) async =>
      _one(await _dio.post('/quotes/$quoteId/reject', data: {'reason': reason}));

  @override
  Future<Quote> counter(String quoteId, {required int price, String? note}) async =>
      _one(await _dio.post('/quotes/$quoteId/counter', data: {'price': price, 'note': note}));

  @override
  Future<Quote> respond(String quoteId, String action) async =>
      _one(await _dio.post('/quotes/$quoteId/negotiation/respond', data: {'action': action}));
}

/// Demo data held in memory so accept / reject / counter can be tried without a server.
class MockQuotesRepository implements QuotesRepository {
  final List<Quote> _quotes = [for (final q in CustomerMockData.quotes) q.copyWith(status: 'PENDING')];

  Quote _replace(String id, Quote Function(Quote) change) {
    final i = _quotes.indexWhere((q) => q.id == id);
    if (i < 0) throw Exception('Quote not found');
    return _quotes[i] = change(_quotes[i]);
  }

  @override
  Future<List<Quote>> forRequirement(String requirementId) async =>
      [for (final q in _quotes) if (q.requirementId == requirementId) q];

  @override
  Future<Quote> accept(String quoteId, {required int expectedPrice}) async {
    final target = _quotes.firstWhere((q) => q.id == quoteId);
    if (target.price != expectedPrice) throw Exception('The price changed. Review the new total before accepting.');
    for (final q in List.of(_quotes)) {
      if (q.requirementId != target.requirementId || q.id == quoteId) continue;
      _replace(q.id, (o) => o.copyWith(status: 'NOT_SELECTED'));
    }
    return _replace(quoteId, (q) => q.copyWith(status: 'ACCEPTED'));
  }

  @override
  Future<Quote> reject(String quoteId, {String? reason}) async =>
      _replace(quoteId, (q) => q.copyWith(status: 'REJECTED', statusReason: reason));

  @override
  Future<Quote> counter(String quoteId, {required int price, String? note}) async => _replace(
        quoteId,
        (q) => q.copyWith(rounds: [
          ...q.rounds,
          QuoteRound(
            id: 'r${q.rounds.length + 1}',
            roundNo: q.rounds.length + 1,
            by: 'CUSTOMER',
            price: price,
            note: note,
            status: 'OPEN',
            validUntil: DateTime.now().add(const Duration(hours: 24)),
          ),
        ]),
      );

  @override
  Future<Quote> respond(String quoteId, String action) async => _replace(quoteId, (q) => q);
}

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockQuotesRepository();
  return ApiQuotesRepository(ref.watch(dioProvider));
});

/// Quotes for one request, cheapest first. Reload after any action with `ref.invalidate`.
final requirementQuotesProvider = FutureProvider.autoDispose.family<List<Quote>, String>((ref, requirementId) async {
  final list = await ref.watch(quotesRepositoryProvider).forRequirement(requirementId);
  return [...list]..sort((a, b) => a.quotedPrice.compareTo(b.quotedPrice));
});
