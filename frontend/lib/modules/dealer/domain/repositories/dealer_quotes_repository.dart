import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../customer/domain/entities/quote.dart';
import '../entities/my_quote.dart';

class QuoteDraft {
  final String requirementId;
  final String? vehicleId;
  final int price;
  final String? message;
  final int validHours;
  final int? deliveryDays;
  final int? warrantyMonths;

  const QuoteDraft({
    required this.requirementId,
    this.vehicleId,
    required this.price,
    this.message,
    this.validHours = 72,
    this.deliveryDays,
    this.warrantyMonths,
  });

  Map<String, dynamic> toJson() => {
    'requirement_id': requirementId,
    if (vehicleId != null) 'vehicle_id': vehicleId,
    'quoted_price': price,
    if ((message ?? '').trim().isNotEmpty) 'message': message!.trim(),
    'valid_hours': validHours,
    if (deliveryDays != null) 'delivery_days': deliveryDays,
    if (warrantyMonths != null) 'warranty_months': warrantyMonths,
  };
}

/// The dealer's side of a quote: send, revise, withdraw, answer a counter-offer.
abstract class DealerQuotesRepository {
  Future<List<MyQuote>> mine();
  Future<void> send(QuoteDraft draft);
  Future<void> revise(String quoteId, {required int price, String? message});
  Future<void> withdraw(String quoteId, {String? reason});

  /// ACCEPT or DECLINE the buyer's counter, or COUNTER with a price between theirs and yours.
  Future<void> reply(String quoteId, String action, {int? price, String? note});
}

class ApiDealerQuotesRepository implements DealerQuotesRepository {
  final Dio _dio;
  ApiDealerQuotesRepository(this._dio);

  @override
  Future<List<MyQuote>> mine() async {
    final res = await _dio.get('/quotes/mine');
    return [
      for (final j in res.data as List)
        MyQuote.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> send(QuoteDraft draft) async {
    await _dio.post('/quotes', data: draft.toJson());
  }

  @override
  Future<void> revise(
    String quoteId, {
    required int price,
    String? message,
  }) async {
    await _dio.put(
      '/quotes/$quoteId',
      data: {'quoted_price': price, 'message': message},
    );
  }

  @override
  Future<void> withdraw(String quoteId, {String? reason}) async {
    await _dio.post('/quotes/$quoteId/withdraw', data: {'reason': reason});
  }

  @override
  Future<void> reply(
    String quoteId,
    String action, {
    int? price,
    String? note,
  }) async {
    await _dio.post(
      '/quotes/$quoteId/negotiation',
      data: {'action': action, 'price': price, 'note': note},
    );
  }
}

class MockDealerQuotesRepository implements DealerQuotesRepository {
  final List<MyQuote> _items = [];

  @override
  Future<List<MyQuote>> mine() async => List.unmodifiable(_items);

  @override
  Future<void> send(QuoteDraft draft) async {
    _items.insert(
      0,
      MyQuote(
        requestTitle: 'Your quote',
        requestCity: '',
        quote: Quote(
          id: 'mq${_items.length + 1}',
          requirementId: draft.requirementId,
          dealerId: 'me',
          dealerName: 'You',
          dealerCity: '',
          carTitle: 'Your car',
          carYear: 0,
          carMileage: 0,
          carFuel: '',
          quotedPrice: draft.price.toDouble(),
          carImageUrl: '',
          comment: draft.message ?? '',
          createdAt: DateTime.now(),
          validUntil: DateTime.now().add(Duration(hours: draft.validHours)),
        ),
      ),
    );
  }

  void _update(String id, Quote Function(Quote) change) {
    final i = _items.indexWhere((m) => m.quote.id == id);
    if (i < 0) return;
    final old = _items[i];
    _items[i] = MyQuote(
      quote: change(old.quote),
      requestTitle: old.requestTitle,
      requestCity: old.requestCity,
      requestStatus: old.requestStatus,
    );
  }

  @override
  Future<void> revise(
    String quoteId, {
    required int price,
    String? message,
  }) async => _update(
    quoteId,
    (q) => q.copyWith(quotedPrice: price.toDouble(), revision: q.revision + 1),
  );

  @override
  Future<void> withdraw(String quoteId, {String? reason}) async => _update(
    quoteId,
    (q) => q.copyWith(status: 'WITHDRAWN', statusReason: reason),
  );

  @override
  Future<void> reply(
    String quoteId,
    String action, {
    int? price,
    String? note,
  }) async {}
}

final dealerQuotesRepositoryProvider = Provider<DealerQuotesRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockDealerQuotesRepository();
  return ApiDealerQuotesRepository(ref.watch(dioProvider));
});

final myQuotesProvider = FutureProvider.autoDispose<List<MyQuote>>((ref) {
  return ref.watch(dealerQuotesRepositoryProvider).mine();
});
