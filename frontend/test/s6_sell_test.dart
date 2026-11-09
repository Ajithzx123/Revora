import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/customer/domain/entities/sell_offer.dart';
import 'package:revora/modules/customer/domain/entities/sell_post.dart';
import 'package:revora/modules/customer/domain/repositories/sell_repository.dart';
import 'package:revora/modules/customer/presentation/ui/listing_details_screen.dart';
import 'package:revora/modules/customer/presentation/ui/post_sell_listing_screen.dart';
import 'package:revora/modules/dealer/domain/entities/my_offer.dart';
import 'package:revora/modules/dealer/domain/entities/sell_lead.dart';
import 'package:revora/modules/dealer/domain/procurement_calculator.dart';
import 'package:revora/modules/dealer/domain/repositories/dealer_offers_repository.dart';
import 'package:revora/modules/dealer/presentation/ui/make_offer_screen.dart';
import 'package:revora/modules/dealer/presentation/widgets/my_offers_view.dart';

Map<String, dynamic> listingJson({String status = 'ACTIVE'}) => {
  'id': 'l1',
  'customer_id': 'c1',
  'make': 'Maruti Suzuki',
  'model': 'Swift',
  'year': 2018,
  'fuel': 'Petrol',
  'transmission': 'Manual',
  'km': 40000,
  'expected_price': 400000,
  'city': 'Bengaluru',
  'images': <String>[],
  'status': status,
  'created_at': '2026-11-02T10:00:00',
  'offer_count': 2,
  'variant': 'ZXi',
  'owners': 2,
  'loan_outstanding': true,
  'loan_amount': 120000,
  'challans_amount': 1500,
  'expires_at': '2026-11-16T10:00:00',
};

Map<String, dynamic> offerJson({
  String status = 'PENDING',
  int price = 380000,
}) => {
  'id': 'o1',
  'dealer_id': 'd1',
  'dealer_name': 'Apex Motors',
  'dealer_rating': 4.6,
  'sell_listing_id': 'l1',
  'offered_price': price,
  'message': 'Cash on pickup',
  'status': status,
  'created_at': '2026-11-02T10:00:00',
  'revision': 2,
  'valid_until': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 30))
      .toIso8601String(),
  'inspection_required': true,
  'pickup_days': 2,
  'loan_settlement_required': true,
};

class FakeSell extends MockSellRepository {
  final List<String> calls = [];
  SellDraft? created;

  @override
  Future<SellPost> create(SellDraft draft) async {
    calls.add('create');
    created = draft;
    return super.create(draft);
  }

  @override
  Future<SellOffer> accept(String offerId, {required int expectedPrice}) async {
    calls.add('accept:$offerId:$expectedPrice');
    return super.accept(offerId, expectedPrice: expectedPrice);
  }

  @override
  Future<SellOffer> reject(String offerId, {String? reason}) async {
    calls.add('reject:$offerId');
    return super.reject(offerId, reason: reason);
  }

  @override
  Future<SellPost> close(
    String listingId, {
    String? reason,
    bool soldElsewhere = false,
  }) async {
    calls.add('close:$listingId:$soldElsewhere');
    return super.close(listingId, reason: reason, soldElsewhere: soldElsewhere);
  }
}

class FakeDealerOffers extends MockDealerOffersRepository {
  final List<OfferDraft> sent = [];

  @override
  Future<void> send(OfferDraft draft) async {
    sent.add(draft);
    return super.send(draft);
  }
}

Widget app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: home),
);

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('models', () {
    test('a listing parses the API shape', () {
      final p = SellPost.fromJson(listingJson());
      expect(p.title, '2018 Maruti Suzuki Swift ZXi');
      expect(p.isOpen, isTrue);
      expect(p.loanOutstanding, isTrue);
      expect(p.expectedPrice, 400000);
      expect(p.expiresAt!.toUtc(), DateTime.utc(2026, 11, 16, 10));
      expect(
        SellPost.fromJson(listingJson(status: 'OFFER_ACCEPTED')).isOpen,
        isFalse,
      );
    });

    test('an offer parses conditions and liveness', () {
      final o = SellOffer.fromJson(offerJson());
      expect(o.price, 380000);
      expect(o.isLive, isTrue);
      expect(o.loanSettlementRequired, isTrue);
      expect(
        SellOffer.fromJson(offerJson(status: 'WITHDRAWN')).isLive,
        isFalse,
      );
    });

    test('a lead carries why it matched and no seller contact', () {
      final lead = SellLead.fromJson({
        ...listingJson(),
        'match_score': 88,
        'match_reasons': ['Buys Maruti Suzuki', 'In Bengaluru'],
        'my_offer_status': null,
      });
      expect(lead.matchScore, 88);
      expect(lead.matchReasons, hasLength(2));
      expect(lead.myOfferStatus, isNull);
    });

    test('the seller contact is only present once the offer is accepted', () {
      final accepted = MyOffer.fromJson({
        ...offerJson(status: 'ACCEPTED'),
        'listing_title': '2018 Maruti Suzuki Swift',
        'seller_name': 'Priya Rao',
        'seller_phone': '+91 90000 00000',
      });
      final pending = MyOffer.fromJson({
        ...offerJson(),
        'listing_title': 'x',
        'seller_first_name': 'Priya',
      });
      expect(accepted.sellerPhone, isNotNull);
      expect(pending.sellerPhone, isNull);
      expect(pending.sellerFirstName, 'Priya');
    });
  });

  group('procurement calculator', () {
    test('margin comes from resale minus offer and your own costs', () {
      final r = ProcurementCalculator.calculate(
        const ProcurementInputs(
          offer: 500000,
          refurbishment: 20000,
          transferRto: 10000,
          holding: 5000,
          expectedResale: 600000,
        ),
      );
      expect(r.totalCost, 535000);
      expect(r.grossMargin, 65000);
      expect(r.marginPercent, closeTo(10.83, 0.01));
      expect(r.profitable, isTrue);
    });

    test(
      'a loan and challans reduce what the seller gets, not the dealer cost',
      () {
        final r = ProcurementCalculator.calculate(
          const ProcurementInputs(
            offer: 500000,
            expectedResale: 600000,
            loanSettlement: 120000,
            challans: 1500,
          ),
        );
        expect(r.totalCost, 500000);
        expect(r.sellerReceives, 378500);
      },
    );

    test('the most you can offer leaves exactly the target margin', () {
      const base = ProcurementInputs(
        offer: 0,
        refurbishment: 20000,
        transferRto: 10000,
        holding: 5000,
        expectedResale: 600000,
      );
      final max = ProcurementCalculator.maxOfferForMargin(base, 10);
      expect(max, 505000); // 600000 - 60000 target - 35000 costs
      final at = ProcurementCalculator.calculate(
        ProcurementInputs(
          offer: max,
          refurbishment: 20000,
          transferRto: 10000,
          holding: 5000,
          expectedResale: 600000,
        ),
      );
      expect(at.marginPercent, closeTo(10, 0.01));
    });

    test('a loss is reported, and an impossible target gives zero', () {
      const i = ProcurementInputs(offer: 700000, expectedResale: 600000);
      expect(ProcurementCalculator.calculate(i).profitable, isFalse);
      expect(
        ProcurementCalculator.maxOfferForMargin(
          const ProcurementInputs(
            offer: 0,
            refurbishment: 900000,
            expectedResale: 600000,
          ),
          10,
        ),
        0,
      );
      expect(
        ProcurementCalculator.calculate(
          const ProcurementInputs(offer: 1, expectedResale: 0),
        ).marginPercent,
        0,
      );
    });
  });

  group('sell wizard', () {
    Future<void> pick(WidgetTester tester, String label, String value) async {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    testWidgets('each step is checked before moving on', (tester) async {
      bigScreen(tester);
      final repo = FakeSell();
      await tester.pumpWidget(
        app(const PostSellListingScreen(), [
          sellRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets); // still on step 1
      // The next step stays hidden: its fields are not on screen.
      expect(find.text('Kilometres driven').hitTestable(), findsNothing);
    });

    testWidgets('a complete listing is sent once with the right values', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = FakeSell();
      await tester.pumpWidget(
        app(const PostSellListingScreen(), [
          sellRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      await pick(tester, 'Make', 'Hyundai');
      await pick(tester, 'Model', 'i20');
      await pick(tester, 'Year', '2019');
      await pick(tester, 'Fuel', 'Petrol');
      await pick(tester, 'Transmission', 'Manual');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kilometres driven'),
        '42000',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Expected price (₹)'),
        '450000',
      );
      await pick(tester, 'City', 'Pune');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('List my car'), findsOneWidget);
      await tester.tap(find.text('List my car'));
      await tester.tap(
        find.text('List my car'),
        warnIfMissed: false,
      ); // a second tap must not send a second listing
      await tester.pumpAndSettle();

      expect(repo.calls, ['create']);
      final d = repo.created!.toJson();
      expect(d['make'], 'Hyundai');
      expect(d['model'], 'i20');
      expect(d['year'], 2019);
      expect(d['km'], 42000);
      expect(d['expected_price'], 450000);
      expect(d['city'], 'Pune');
      expect(d['urgency'], 'NORMAL');
      expect(d['loan_outstanding'], false);
      expect(d.containsKey('loan_amount'), isFalse);
    });
  });

  group('offers on a listing', () {
    Future<FakeSell> open(WidgetTester tester) async {
      bigScreen(tester);
      final repo = FakeSell();
      await tester.pumpWidget(
        app(const ListingDetailsScreen(listingId: 'SELL-301'), [
          sellRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('shows offers highest first and marks the best', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Highest offer'), findsOneWidget);
      final first = tester.getTopLeft(find.text('City Pre-owned')).dy;
      final second = tester.getTopLeft(find.text('Fast Deals Cars')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('accepting asks first, then sends the price the seller saw', (
      tester,
    ) async {
      final repo = await open(tester);
      await tester.tap(find.text('Accept offer').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be reopened'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Accept offer').last);
      await tester.pumpAndSettle();
      expect(repo.calls.single, startsWith('accept:SELL-301-o1:'));
      expect(
        find.text('Accept offer'),
        findsNothing,
      ); // the listing is no longer open
    });

    testWidgets('declining the confirmation sends nothing', (tester) async {
      final repo = await open(tester);
      await tester.tap(find.text('Accept offer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
    });

    testWidgets(
      'turning an offer down and closing the listing both ask first',
      (tester) async {
        final repo = await open(tester);
        await tester.tap(find.text('Turn down').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Turn down'));
        await tester.pumpAndSettle();
        expect(repo.calls, ['reject:SELL-301-o1']);

        await tester.tap(find.text('Sold elsewhere'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, sold'));
        await tester.pumpAndSettle();
        expect(repo.calls.last, 'close:SELL-301:true');
        expect(
          find.text('Sold elsewhere'),
          findsNothing,
        ); // closed listings offer no actions
      },
    );
  });

  group('dealer offer flow', () {
    testWidgets('the calculator shows margin and the most you can offer', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = FakeDealerOffers();
      await tester.pumpWidget(
        app(const MakeOfferScreen(listingId: 'SLEAD-01'), [
          dealerOffersRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Loan running'), findsOneWidget);
      expect(
        find.textContaining('Enter an expected resale price'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Expected resale price (₹)'),
        '700000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Refurbishment (₹)'),
        '20000',
      );
      await tester.pump();
      expect(find.text('Gross margin'), findsOneWidget);
      expect(
        find.textContaining('Use ₹'),
        findsOneWidget,
      ); // suggested maximum for the 8% target
    });

    testWidgets('an offer needs a price, then is sent once', (tester) async {
      bigScreen(tester);
      final repo = FakeDealerOffers();
      await tester.pumpWidget(
        app(const MakeOfferScreen(listingId: 'SLEAD-01'), [
          dealerOffersRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Offer price (₹)'),
        '',
      );
      await tester.tap(find.text('Send offer'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(repo.sent, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Offer price (₹)'),
        '600000',
      );
      await tester.tap(find.text('Send offer'));
      await tester.tap(find.text('Send offer'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(repo.sent, hasLength(1));
      expect(repo.sent.single.price, 600000);
      expect(repo.sent.single.inspectionRequired, isTrue);
      expect(repo.sent.single.validHours, 48);
    });

    testWidgets(
      'my offers are empty, then show a sent offer that can be withdrawn',
      (tester) async {
        bigScreen(tester);
        final repo = FakeDealerOffers();
        await tester.pumpWidget(
          app(const Scaffold(body: MyOffersView()), [
            dealerOffersRepositoryProvider.overrideWithValue(repo),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text('No offers yet'), findsOneWidget);

        await repo.send(const OfferDraft(listingId: 'SLEAD-01', price: 600000));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MyOffersView)),
        );
        container.invalidate(myOffersProvider);
        await tester.pumpAndSettle();
        expect(find.text('Revise price'), findsOneWidget);

        await tester.tap(find.text('Withdraw'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
        await tester.pumpAndSettle();
        expect(find.text('Withdrawn'), findsWidgets);
        expect(find.text('Revise price'), findsNothing);
      },
    );
  });
}
