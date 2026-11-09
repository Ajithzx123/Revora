import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/mock/customer_mock_data.dart';
import '../entities/sell_offer.dart';
import '../entities/sell_post.dart';

/// What the seller fills in on the sell wizard.
class SellDraft {
  final String make;
  final String model;
  final String? variant;
  final int year;
  final String fuel;
  final String transmission;
  final String? color;
  final int km;
  final int owners;
  final bool? insuranceValid;
  final bool loanOutstanding;
  final int? loanAmount;
  final int? challansAmount;
  final String? description;
  final int expectedPrice;
  final String city;
  final String urgency;

  const SellDraft({
    required this.make,
    required this.model,
    this.variant,
    required this.year,
    required this.fuel,
    required this.transmission,
    this.color,
    required this.km,
    this.owners = 1,
    this.insuranceValid,
    this.loanOutstanding = false,
    this.loanAmount,
    this.challansAmount,
    this.description,
    required this.expectedPrice,
    required this.city,
    this.urgency = 'NORMAL',
  });

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    if ((variant ?? '').trim().isNotEmpty) 'variant': variant!.trim(),
    'year': year,
    'fuel': fuel,
    'transmission': transmission,
    if (color != null) 'color': color,
    'km': km,
    'owners': owners,
    if (insuranceValid != null) 'insurance_valid': insuranceValid,
    'loan_outstanding': loanOutstanding,
    if (loanOutstanding && loanAmount != null) 'loan_amount': loanAmount,
    if (challansAmount != null) 'challans_amount': challansAmount,
    if ((description ?? '').trim().isNotEmpty)
      'description': description!.trim(),
    'expected_price': expectedPrice,
    'city': city,
    'urgency': urgency,
  };
}

/// The seller's side: list a car, watch the offers, accept one, change the price or close.
abstract class SellRepository {
  Future<List<SellPost>> listings();
  Future<SellPost> create(SellDraft draft);
  Future<SellPost> changePrice(String listingId, int price);
  Future<SellPost> close(
    String listingId, {
    String? reason,
    bool soldElsewhere = false,
  });

  /// Highest price first.
  Future<List<SellOffer>> offers(String listingId);

  /// Fails if the dealer changed the price meanwhile (`expectedPrice` is what the seller saw).
  Future<SellOffer> accept(String offerId, {required int expectedPrice});
  Future<SellOffer> reject(String offerId, {String? reason});

  /// Ask for more than the dealer offered. The dealer has 24 hours to answer.
  Future<SellOffer> counter(String offerId, {required int price, String? note});

  /// Answer the dealer's counter: ACCEPT or DECLINE.
  Future<SellOffer> respond(String offerId, String action);

  /// Answer the dealer's lowered price after inspection: ACCEPT, or DECLINE for free.
  Future<SellOffer> respondFinal(String offerId, String action);
}

class ApiSellRepository implements SellRepository {
  final Dio _dio;
  ApiSellRepository(this._dio);

  SellPost _post(Response<dynamic> r) =>
      SellPost.fromJson(r.data as Map<String, dynamic>);
  SellOffer _offer(Response<dynamic> r) =>
      SellOffer.fromJson(r.data as Map<String, dynamic>);

  @override
  Future<List<SellPost>> listings() async {
    final res = await _dio.get('/sell-listings/');
    return [
      for (final j in res.data as List)
        SellPost.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<SellPost> create(SellDraft draft) async =>
      _post(await _dio.post('/sell-listings/', data: draft.toJson()));

  @override
  Future<SellPost> changePrice(String listingId, int price) async => _post(
    await _dio.put(
      '/sell-listings/$listingId/price',
      data: {'expected_price': price},
    ),
  );

  @override
  Future<SellPost> close(
    String listingId, {
    String? reason,
    bool soldElsewhere = false,
  }) async => _post(
    await _dio.post(
      '/sell-listings/$listingId/close',
      data: {'reason': reason, 'sold_elsewhere': soldElsewhere},
    ),
  );

  @override
  Future<List<SellOffer>> offers(String listingId) async {
    final res = await _dio.get('/sell-listings/$listingId/offers');
    return [
      for (final j in res.data as List)
        SellOffer.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<SellOffer> accept(
    String offerId, {
    required int expectedPrice,
  }) async => _offer(
    await _dio.post(
      '/offers/$offerId/accept',
      data: {'expected_price': expectedPrice},
    ),
  );

  @override
  Future<SellOffer> reject(String offerId, {String? reason}) async => _offer(
    await _dio.post('/offers/$offerId/reject', data: {'reason': reason}),
  );

  @override
  Future<SellOffer> counter(
    String offerId, {
    required int price,
    String? note,
  }) async => _offer(
    await _dio.post(
      '/offers/$offerId/counter',
      data: {'price': price, 'note': note},
    ),
  );

  @override
  Future<SellOffer> respond(String offerId, String action) async => _offer(
    await _dio.post(
      '/offers/$offerId/negotiation/respond',
      data: {'action': action},
    ),
  );

  @override
  Future<SellOffer> respondFinal(String offerId, String action) async => _offer(
    await _dio.post('/offers/$offerId/final/respond', data: {'action': action}),
  );
}

/// Demo data held in memory so the whole sell journey can be tried without a server.
class MockSellRepository implements SellRepository {
  final List<SellPost> _posts = List.of(CustomerMockData.sellPosts);
  final List<SellOffer> _offers = [];

  MockSellRepository() {
    for (final p in _posts) {
      _offers.addAll([
        SellOffer(
          id: '${p.id}-o1',
          dealerId: 'd1',
          dealerName: 'City Pre-owned',
          dealerRating: 4.8,
          listingId: p.id,
          price: (p.expectedPrice * 1.02).round(),
          validUntil: DateTime.now().add(const Duration(hours: 40)),
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        SellOffer(
          id: '${p.id}-o2',
          dealerId: 'd2',
          dealerName: 'Fast Deals Cars',
          dealerRating: 4.5,
          listingId: p.id,
          price: (p.expectedPrice * 0.95).round(),
          pickupDays: 2,
          validUntil: DateTime.now().add(const Duration(hours: 20)),
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ]);
    }
  }

  /// Test hook: put an offer in a specific state.
  void seedOffer(SellOffer offer) {
    _offers.removeWhere((o) => o.id == offer.id);
    _offers.add(offer);
  }

  SellPost _replacePost(String id, SellPost Function(SellPost) change) {
    final i = _posts.indexWhere((p) => p.id == id);
    if (i < 0) throw Exception('Listing not found');
    return _posts[i] = change(_posts[i]);
  }

  SellPost _with(SellPost p, {int? price, String? status, String? reason}) =>
      SellPost(
        id: p.id,
        make: p.make,
        model: p.model,
        year: p.year,
        variant: p.variant,
        mileage: p.mileage,
        fuelType: p.fuelType,
        transmission: p.transmission,
        expectedPrice: price ?? p.expectedPrice,
        city: p.city,
        status: status ?? p.status,
        statusReason: reason ?? p.statusReason,
        offersCount: p.offersCount,
        imageUrls: p.imageUrls,
        createdAt: p.createdAt,
        owners: p.owners,
        color: p.color,
        urgency: p.urgency,
        loanOutstanding: p.loanOutstanding,
        loanAmount: p.loanAmount,
        challansAmount: p.challansAmount,
        insuranceValid: p.insuranceValid,
        description: p.description,
        expiresAt: p.expiresAt,
      );

  @override
  Future<List<SellPost>> listings() async => List.unmodifiable(_posts);

  @override
  Future<SellPost> create(SellDraft d) async {
    final post = SellPost(
      id: 'SELL-${300 + _posts.length + 1}',
      make: d.make,
      model: d.model,
      year: d.year,
      variant: d.variant ?? '',
      mileage: d.km,
      fuelType: d.fuel,
      transmission: d.transmission,
      expectedPrice: d.expectedPrice,
      city: d.city,
      imageUrls: const [],
      createdAt: DateTime.now(),
      owners: d.owners,
      color: d.color,
      urgency: d.urgency,
      loanOutstanding: d.loanOutstanding,
      loanAmount: d.loanAmount,
      challansAmount: d.challansAmount,
      insuranceValid: d.insuranceValid,
      description: d.description,
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    );
    _posts.insert(0, post);
    return post;
  }

  @override
  Future<SellPost> changePrice(String listingId, int price) async =>
      _replacePost(listingId, (p) => _with(p, price: price));

  @override
  Future<SellPost> close(
    String listingId, {
    String? reason,
    bool soldElsewhere = false,
  }) async {
    for (var i = 0; i < _offers.length; i++) {
      if (_offers[i].listingId == listingId && _offers[i].isLive) {
        _offers[i] = _offers[i].copyWith(status: 'NOT_SELECTED');
      }
    }
    return _replacePost(
      listingId,
      (p) => _with(
        p,
        status: 'CLOSED',
        reason: reason ?? (soldElsewhere ? 'Sold elsewhere' : null),
      ),
    );
  }

  @override
  Future<List<SellOffer>> offers(String listingId) async => [
    for (final o in _offers)
      if (o.listingId == listingId) o,
  ]..sort((a, b) => b.price.compareTo(a.price));

  @override
  Future<SellOffer> accept(String offerId, {required int expectedPrice}) async {
    final target = _offers.firstWhere((o) => o.id == offerId);
    if (target.price != expectedPrice) {
      throw Exception(
        'The offer changed. Review the new price before accepting.',
      );
    }
    for (var i = 0; i < _offers.length; i++) {
      final o = _offers[i];
      if (o.listingId != target.listingId || o.id == offerId) continue;
      if (o.isLive) _offers[i] = o.copyWith(status: 'NOT_SELECTED');
    }
    _replacePost(target.listingId, (p) => _with(p, status: 'OFFER_ACCEPTED'));
    final i = _offers.indexWhere((o) => o.id == offerId);
    return _offers[i] = _offers[i].copyWith(status: 'ACCEPTED');
  }

  @override
  Future<SellOffer> reject(String offerId, {String? reason}) async {
    final i = _offers.indexWhere((o) => o.id == offerId);
    return _offers[i] = _offers[i].copyWith(
      status: 'REJECTED',
      statusReason: reason,
    );
  }

  SellOffer _replaceOffer(String id, SellOffer Function(SellOffer) change) {
    final i = _offers.indexWhere((o) => o.id == id);
    if (i < 0) throw Exception('Offer not found');
    return _offers[i] = change(_offers[i]);
  }

  @override
  Future<SellOffer> counter(
    String offerId, {
    required int price,
    String? note,
  }) async => _replaceOffer(offerId, (o) {
    if (price <= o.price) {
      throw Exception('A counter-offer must be higher than the offered price');
    }
    return o.copyWith(
      rounds: [
        ...o.rounds,
        OfferRound(
          id: '$offerId-r${o.rounds.length + 1}',
          roundNo: o.rounds.length + 1,
          by: 'SELLER',
          price: price,
          note: note,
          status: 'OPEN',
          validUntil: DateTime.now().add(const Duration(hours: 24)),
        ),
      ],
    );
  });

  @override
  Future<SellOffer> respond(String offerId, String action) async =>
      _replaceOffer(offerId, (o) {
        final open = o.openRound;
        if (open == null) throw Exception('There is no counter-offer waiting');
        final closed = [
          for (final r in o.rounds)
            if (r.id == open.id)
              OfferRound(
                id: r.id,
                roundNo: r.roundNo,
                by: r.by,
                price: r.price,
                note: r.note,
                status: action == 'ACCEPT' ? 'AGREED' : 'DECLINED',
                validUntil: r.validUntil,
              )
            else
              r,
        ];
        return o.copyWith(
          rounds: closed,
          price: action == 'ACCEPT' ? open.price : null,
        );
      });

  @override
  Future<SellOffer> respondFinal(String offerId, String action) async {
    final offer = _replaceOffer(offerId, (o) {
      if (!o.finalAwaitingSeller) {
        throw Exception('There is no final offer waiting for your answer');
      }
      return action == 'ACCEPT'
          ? o.copyWith(finalStatus: 'ACCEPTED')
          : o.copyWith(
              finalStatus: 'DECLINED',
              status: 'REJECTED',
              statusReason: 'The seller declined the price after inspection',
            );
    });
    _replacePost(
      offer.listingId,
      (p) => _with(p, status: action == 'ACCEPT' ? 'FINAL_ACCEPTED' : 'ACTIVE'),
    );
    return offer;
  }
}

final sellRepositoryProvider = Provider<SellRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockSellRepository();
  return ApiSellRepository(ref.watch(dioProvider));
});

/// The seller's listings, newest first.
final sellListingsProvider = FutureProvider.autoDispose<List<SellPost>>((ref) {
  return ref.watch(sellRepositoryProvider).listings();
});

final listingOffersProvider = FutureProvider.autoDispose
    .family<List<SellOffer>, String>((ref, listingId) {
      return ref.watch(sellRepositoryProvider).offers(listingId);
    });
