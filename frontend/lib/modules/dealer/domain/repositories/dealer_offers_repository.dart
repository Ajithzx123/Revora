import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../customer/domain/entities/sell_offer.dart';
import '../../../customer/domain/entities/sell_post.dart';
import '../entities/my_offer.dart';
import '../entities/sell_lead.dart';

class OfferDraft {
  final String listingId;
  final int price;
  final String? message;
  final int validHours;
  final bool inspectionRequired;
  final int? pickupDays;

  const OfferDraft({
    required this.listingId,
    required this.price,
    this.message,
    this.validHours = 48,
    this.inspectionRequired = true,
    this.pickupDays,
  });

  Map<String, dynamic> toJson() => {
    'sell_listing_id': listingId,
    'offered_price': price,
    if ((message ?? '').trim().isNotEmpty) 'message': message!.trim(),
    'valid_hours': validHours,
    'inspection_required': inspectionRequired,
    if (pickupDays != null) 'pickup_days': pickupDays,
  };
}

/// The price after inspecting the car: the accepted price confirmed, or a lower one with a
/// reason (and evidence when the drop is more than 5%).
class FinalDraft {
  final int price;
  final String? reasonCode;
  final String? reasonNote;
  final List<String> evidenceUrls;

  const FinalDraft({
    required this.price,
    this.reasonCode,
    this.reasonNote,
    this.evidenceUrls = const [],
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    if (reasonCode != null) 'reason_code': reasonCode,
    if ((reasonNote ?? '').trim().isNotEmpty) 'reason_note': reasonNote!.trim(),
    'evidence_urls': evidenceUrls,
  };
}

/// The dealer's side of the sell journey: see matched cars, make and manage offers.
abstract class DealerOffersRepository {
  Future<List<SellLead>> leads();
  Future<void> send(OfferDraft draft);
  Future<List<MyOffer>> mine();
  Future<void> revise(String offerId, {required int price, String? message});
  Future<void> withdraw(String offerId);

  /// ACCEPT or DECLINE the seller's counter, or COUNTER with a price between yours and theirs.
  Future<void> reply(String offerId, String action, {int? price, String? note});

  /// After the seller accepts: confirm the price, or lower it with a reason.
  Future<void> submitFinal(String offerId, FinalDraft draft);
}

class ApiDealerOffersRepository implements DealerOffersRepository {
  final Dio _dio;
  ApiDealerOffersRepository(this._dio);

  @override
  Future<List<SellLead>> leads() async {
    final res = await _dio.get('/leads/sell');
    return [
      for (final j in res.data as List)
        SellLead.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> send(OfferDraft draft) async {
    await _dio.post('/offers', data: draft.toJson());
  }

  @override
  Future<List<MyOffer>> mine() async {
    final res = await _dio.get('/offers/mine');
    return [
      for (final j in res.data as List)
        MyOffer.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> revise(
    String offerId, {
    required int price,
    String? message,
  }) async {
    await _dio.put(
      '/offers/$offerId',
      data: {'offered_price': price, 'message': message},
    );
  }

  @override
  Future<void> withdraw(String offerId) async {
    await _dio.post('/offers/$offerId/withdraw');
  }

  @override
  Future<void> reply(
    String offerId,
    String action, {
    int? price,
    String? note,
  }) async {
    await _dio.post(
      '/offers/$offerId/negotiation',
      data: {'action': action, 'price': price, 'note': note},
    );
  }

  @override
  Future<void> submitFinal(String offerId, FinalDraft draft) async {
    await _dio.post('/offers/$offerId/final', data: draft.toJson());
  }
}

class MockDealerOffersRepository implements DealerOffersRepository {
  final List<SellLead> _leads = [
    SellLead(
      listing: SellPost(
        id: 'SLEAD-01',
        make: 'Maruti Suzuki',
        model: 'Swift',
        year: 2020,
        variant: 'ZXi AMT',
        mileage: 38000,
        fuelType: 'Petrol',
        transmission: 'Automatic',
        expectedPrice: 620000,
        city: 'Mumbai',
        imageUrls: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        loanOutstanding: true,
        loanAmount: 150000,
      ),
      matchScore: 92,
      matchReasons: const ['Buys Maruti Suzuki', 'In Mumbai'],
    ),
    SellLead(
      listing: SellPost(
        id: 'SLEAD-02',
        make: 'Hyundai',
        model: 'Venue',
        year: 2021,
        variant: 'SX Plus DCT',
        mileage: 26000,
        fuelType: 'Petrol',
        transmission: 'Automatic',
        expectedPrice: 940000,
        city: 'Thane',
        imageUrls: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
      matchScore: 81,
      matchReasons: const ['Buys Hyundai', '24 km away in Thane'],
    ),
  ];
  final List<MyOffer> _offers = [];

  @override
  Future<List<SellLead>> leads() async => List.unmodifiable(_leads);

  @override
  Future<void> send(OfferDraft draft) async {
    final lead = _leads.firstWhere((l) => l.id == draft.listingId);
    _offers.insert(
      0,
      MyOffer(
        listingTitle: lead.listing.title,
        listingCity: lead.listing.city,
        listingStatus: 'ACTIVE',
        offer: SellOffer(
          id: 'mo${_offers.length + 1}',
          dealerId: 'me',
          dealerName: 'You',
          listingId: draft.listingId,
          price: draft.price,
          message: draft.message,
          validUntil: DateTime.now().add(Duration(hours: draft.validHours)),
          inspectionRequired: draft.inspectionRequired,
          pickupDays: draft.pickupDays,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<List<MyOffer>> mine() async => List.unmodifiable(_offers);

  void _update(String id, SellOffer Function(SellOffer) change) {
    final i = _offers.indexWhere((m) => m.offer.id == id);
    if (i < 0) return;
    final old = _offers[i];
    _offers[i] = MyOffer(
      offer: change(old.offer),
      listingTitle: old.listingTitle,
      listingCity: old.listingCity,
      listingStatus: old.listingStatus,
    );
  }

  @override
  Future<void> revise(
    String offerId, {
    required int price,
    String? message,
  }) async => _update(
    offerId,
    (o) => SellOffer(
      id: o.id,
      dealerId: o.dealerId,
      dealerName: o.dealerName,
      listingId: o.listingId,
      price: price,
      message: message ?? o.message,
      revision: o.revision + 1,
      validUntil: o.validUntil,
      inspectionRequired: o.inspectionRequired,
      pickupDays: o.pickupDays,
      createdAt: o.createdAt,
    ),
  );

  @override
  Future<void> withdraw(String offerId) async =>
      _update(offerId, (o) => o.copyWith(status: 'WITHDRAWN'));

  @override
  Future<void> reply(
    String offerId,
    String action, {
    int? price,
    String? note,
  }) async => _update(offerId, (o) {
    final open = o.openRound;
    if (open == null) throw Exception('There is no counter-offer waiting');
    OfferRound closeWith(String status) => OfferRound(
      id: open.id,
      roundNo: open.roundNo,
      by: open.by,
      price: open.price,
      note: open.note,
      status: status,
      validUntil: open.validUntil,
    );
    final others = [
      for (final r in o.rounds)
        if (r.id != open.id) r,
    ];
    switch (action) {
      case 'ACCEPT':
        return o.copyWith(
          rounds: [...others, closeWith('AGREED')],
          price: open.price,
        );
      case 'DECLINE':
        return o.copyWith(rounds: [...others, closeWith('DECLINED')]);
      default:
        if (price == null || price <= o.price || price >= open.price) {
          throw Exception(
            'Your counter must be above your offer and below the seller\'s ask',
          );
        }
        return o.copyWith(
          rounds: [
            ...others,
            closeWith('COUNTERED'),
            OfferRound(
              id: '${o.id}-r${o.rounds.length + 1}',
              roundNo: o.rounds.length + 1,
              by: 'DEALER',
              price: price,
              status: 'OPEN',
              validUntil: DateTime.now().add(const Duration(hours: 24)),
            ),
          ],
        );
    }
  });

  @override
  Future<void> submitFinal(String offerId, FinalDraft draft) async =>
      _update(offerId, (o) {
        if (!o.awaitingInspection) {
          throw Exception('A final offer follows an accepted offer');
        }
        final same = draft.price == o.price;
        return o.copyWith(
          finalStatus: same ? 'ACCEPTED' : 'SUBMITTED',
          finalPrice: draft.price,
          finalDropPercent: (o.price - draft.price) * 100 / o.price,
          finalReasonCode: draft.reasonCode,
          finalReasonNote: draft.reasonNote,
          finalEvidence: draft.evidenceUrls,
        );
      });

  /// Test hook: put an offer in a specific state.
  void seed(MyOffer offer) {
    _offers.removeWhere((m) => m.offer.id == offer.offer.id);
    _offers.insert(0, offer);
  }
}

final dealerOffersRepositoryProvider = Provider<DealerOffersRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockDealerOffersRepository();
  return ApiDealerOffersRepository(ref.watch(dioProvider));
});

/// Cars matched to this dealer, best match first.
final sellLeadsProvider = FutureProvider.autoDispose<List<SellLead>>((ref) {
  return ref.watch(dealerOffersRepositoryProvider).leads();
});

final myOffersProvider = FutureProvider.autoDispose<List<MyOffer>>((ref) {
  return ref.watch(dealerOffersRepositoryProvider).mine();
});
