import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/customer/domain/entities/sell_offer.dart';
import 'package:revora/modules/customer/domain/repositories/sell_repository.dart';
import 'package:revora/modules/customer/presentation/ui/listing_details_screen.dart';
import 'package:revora/modules/dealer/domain/entities/my_offer.dart';
import 'package:revora/modules/dealer/domain/final_offer_rules.dart';
import 'package:revora/modules/dealer/domain/repositories/dealer_offers_repository.dart';
import 'package:revora/modules/dealer/presentation/widgets/my_offers_view.dart';

OfferRound round(String by, int price, {String status = 'OPEN'}) => OfferRound(
  id: 'r-$by-$price',
  roundNo: 1,
  by: by,
  price: price,
  status: status,
  validUntil: DateTime.now().add(const Duration(hours: 20)),
);

SellOffer offer({
  String id = 'SELL-301-o1',
  String status = 'PENDING',
  int price = 400000,
  List<OfferRound> rounds = const [],
  bool inspection = true,
  String? finalStatus,
  int? finalPrice,
  double? drop,
  String? reason,
  List<String> evidence = const [],
}) => SellOffer(
  id: id,
  dealerId: 'd1',
  dealerName: 'City Pre-owned',
  listingId: 'SELL-301',
  price: price,
  status: status,
  validUntil: DateTime.now().add(const Duration(hours: 30)),
  inspectionRequired: inspection,
  createdAt: DateTime.now(),
  rounds: rounds,
  finalStatus: finalStatus,
  finalPrice: finalPrice,
  finalDropPercent: drop,
  finalReasonCode: reason,
  finalEvidence: evidence,
);

class FakeSell extends MockSellRepository {
  final List<String> calls = [];

  @override
  Future<SellOffer> counter(
    String offerId, {
    required int price,
    String? note,
  }) async {
    calls.add('counter:$price');
    return super.counter(offerId, price: price, note: note);
  }

  @override
  Future<SellOffer> respond(String offerId, String action) async {
    calls.add('respond:$action');
    return super.respond(offerId, action);
  }

  @override
  Future<SellOffer> respondFinal(String offerId, String action) async {
    calls.add('final:$action');
    return super.respondFinal(offerId, action);
  }
}

class FakeDealer extends MockDealerOffersRepository {
  final List<String> calls = [];
  FinalDraft? finalDraft;

  @override
  Future<void> reply(
    String offerId,
    String action, {
    int? price,
    String? note,
  }) async {
    calls.add('reply:$action:${price ?? ''}');
    return super.reply(offerId, action, price: price, note: note);
  }

  @override
  Future<void> submitFinal(String offerId, FinalDraft draft) async {
    calls.add('final:${draft.price}');
    finalDraft = draft;
    return super.submitFinal(offerId, draft);
  }
}

Widget app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: home),
);

void bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(900, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

MyOffer mine(SellOffer o) => MyOffer(
  offer: o,
  listingTitle: '2020 Maruti Suzuki Swift',
  listingCity: 'Mumbai',
);

void main() {
  group('model and rules', () {
    test('parses rounds and the final offer', () {
      final o = SellOffer.fromJson({
        'id': 'o1',
        'dealer_id': 'd',
        'dealer_name': 'Apex',
        'sell_listing_id': 'l',
        'offered_price': 400000,
        'status': 'ACCEPTED',
        'created_at': '2026-11-02T10:00:00',
        'rounds': [
          {
            'id': 'r1',
            'round_no': 1,
            'by': 'SELLER',
            'price': 420000,
            'status': 'AGREED',
            'valid_until': '2026-11-03T10:00:00',
          },
        ],
        'final_status': 'SUBMITTED',
        'final_price': 360000,
        'final_drop_percent': 10.0,
        'final_reason_code': 'UNDISCLOSED_ACCIDENT',
        'final_evidence': ['https://x/1.jpg'],
      });
      expect(o.rounds.single.by, 'SELLER');
      expect(o.openRound, isNull); // agreed, not open
      expect(o.finalAwaitingSeller, isTrue);
      expect(o.awaitingInspection, isFalse);
      expect(o.finalEvidence, ['https://x/1.jpg']);
    });

    test(
      'awaiting inspection means accepted, inspected, and no final price yet',
      () {
        expect(offer(status: 'ACCEPTED').awaitingInspection, isTrue);
        expect(
          offer(status: 'ACCEPTED', inspection: false).awaitingInspection,
          isFalse,
        );
        expect(
          offer(
            status: 'ACCEPTED',
            finalStatus: 'SUBMITTED',
          ).awaitingInspection,
          isFalse,
        );
        expect(
          offer(rounds: [round('DEALER', 410000)]).openRound!.by,
          'DEALER',
        );
      },
    );

    test('final offer rules match the server', () {
      String? check(int price, {String? reason, List<String> ev = const []}) =>
          FinalOfferRules.check(
            accepted: 400000,
            price: price,
            reasonCode: reason,
            evidence: ev,
          );
      expect(check(400000), isNull); // confirm: nothing else needed
      expect(check(410000), contains('higher'));
      expect(check(0), isNotNull);
      expect(check(390000), contains('why')); // lower needs a reason
      expect(
        check(390000, reason: 'OTHER'),
        isNull,
      ); // 2.5% drop: reason is enough
      expect(
        check(370000, reason: 'OTHER'),
        contains('evidence'),
      ); // 7.5% drop needs evidence
      expect(check(370000, reason: 'OTHER', ev: ['https://x']), isNull);
      expect(check(380000, reason: 'OTHER'), isNull); // exactly 5% needs none
    });
  });

  group('seller negotiation', () {
    Future<FakeSell> open(WidgetTester tester, SellOffer seeded) async {
      bigScreen(tester);
      final repo = FakeSell()..seedOffer(seeded);
      await tester.pumpWidget(
        app(const ListingDetailsScreen(listingId: 'SELL-301'), [
          sellRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('asking for more sends a higher counter', (tester) async {
      // The highest offer is listed first; 700000 puts this one on top of the demo offers.
      final repo = await open(tester, offer(price: 700000));
      await tester.tap(find.text('Ask for more').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '650000',
      ); // not higher than the offer
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(find.textContaining('Must be higher'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '720000');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['counter:720000']);
      expect(find.textContaining('You asked'), findsOneWidget);
      // One counter at a time: only the other demo offer can still be countered.
      expect(find.text('Ask for more'), findsOneWidget);
    });

    testWidgets("answering the dealer's counter", (tester) async {
      final repo = await open(tester, offer(rounds: [round('DEALER', 410000)]));
      expect(find.textContaining('The dealer countered'), findsOneWidget);
      await tester.tap(find.textContaining('Take '));
      await tester.pumpAndSettle();
      expect(repo.calls, ['respond:ACCEPT']);
      expect(find.textContaining('The dealer countered'), findsNothing);
    });
  });

  group('inspection: seller side', () {
    Future<FakeSell> open(WidgetTester tester, SellOffer seeded) async {
      bigScreen(tester);
      final repo = FakeSell()..seedOffer(seeded);
      await tester.pumpWidget(
        app(const ListingDetailsScreen(listingId: 'SELL-301'), [
          sellRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    final lowered = offer(
      status: 'ACCEPTED',
      finalStatus: 'SUBMITTED',
      finalPrice: 360000,
      drop: 10.0,
      reason: 'UNDISCLOSED_ACCIDENT',
      evidence: ['https://files.example/p1.jpg'],
    );

    testWidgets('an accepted offer says the dealer will inspect', (
      tester,
    ) async {
      await open(tester, offer(status: 'ACCEPTED'));
      expect(find.textContaining('inspects the car'), findsOneWidget);
    });

    testWidgets(
      'a lower final price shows the reason, the evidence and a free decline',
      (tester) async {
        await open(tester, lowered);
        expect(
          find.textContaining('Final offer after inspection'),
          findsOneWidget,
        );
        expect(find.textContaining('10.0%'), findsOneWidget);
        expect(find.textContaining('undisclosed accident'), findsOneWidget);
        expect(find.textContaining('files.example/p1.jpg'), findsOneWidget);
        expect(find.textContaining('Declining is free'), findsOneWidget);
      },
    );

    testWidgets('accepting the lower price asks first', (tester) async {
      final repo = await open(tester, lowered);
      await tester.tap(find.textContaining('Accept ₹'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['final:ACCEPT']);
      expect(
        find.textContaining('You accepted the final price'),
        findsOneWidget,
      );
    });

    testWidgets('declining reopens the listing', (tester) async {
      final repo = await open(tester, lowered);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('that are still valid come back'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['final:DECLINE']);
      expect(find.text('Open for offers'), findsOneWidget);
    });
  });

  group('dealer side', () {
    Future<FakeDealer> open(WidgetTester tester, SellOffer seeded) async {
      bigScreen(tester);
      final repo = FakeDealer()..seed(mine(seeded));
      await tester.pumpWidget(
        app(const Scaffold(body: MyOffersView()), [
          dealerOffersRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets("answering the seller's counter", (tester) async {
      final repo = await open(tester, offer(rounds: [round('SELLER', 430000)]));
      expect(find.textContaining('The seller asks'), findsOneWidget);
      await tester.tap(find.textContaining('Agree '));
      await tester.pumpAndSettle();
      expect(repo.calls, ['reply:ACCEPT:']);
      expect(find.textContaining('The seller asks'), findsNothing);
    });

    testWidgets('a counter must sit between the two prices', (tester) async {
      final repo = await open(tester, offer(rounds: [round('SELLER', 430000)]));
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '440000'); // above the ask
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      await tester.enterText(find.byType(TextField), '415000');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['reply:COUNTER:415000']);
      expect(find.textContaining('You countered at'), findsOneWidget);
    });

    testWidgets('confirming the same price needs nothing else', (tester) async {
      final repo = await open(tester, offer(status: 'ACCEPTED'));
      await tester.tap(find.text('Send final offer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm price'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['final:400000']);
      expect(repo.finalDraft!.reasonCode, isNull);
      expect(find.textContaining('Final price agreed'), findsOneWidget);
    });

    testWidgets(
      'a big drop needs a reason and evidence before it can be sent',
      (tester) async {
        final repo = await open(tester, offer(status: 'ACCEPTED'));
        await tester.tap(find.text('Send final offer'));
        await tester.pumpAndSettle();

        FilledButton send() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Send lower price'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Final price (₹)'),
          '360000',
        );
        await tester.pump();
        expect(send().onPressed, isNull); // no reason yet
        expect(find.textContaining('Choose why'), findsOneWidget);

        await tester.tap(find.text('Why is it lower?'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Undisclosed accident').last);
        await tester.pumpAndSettle();
        expect(send().onPressed, isNull); // 10% drop: still needs evidence
        expect(find.textContaining('needs evidence'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Evidence links (required)'),
          'https://files.example/p1.jpg\nhttps://files.example/r.pdf',
        );
        await tester.pump();
        expect(send().onPressed, isNotNull);
        await tester.tap(find.text('Send lower price'));
        await tester.pumpAndSettle();

        expect(repo.calls, ['final:360000']);
        expect(repo.finalDraft!.reasonCode, 'UNDISCLOSED_ACCIDENT');
        expect(repo.finalDraft!.evidenceUrls, hasLength(2));
        expect(
          find.textContaining('Waiting for the seller to answer'),
          findsOneWidget,
        );
        expect(find.text('Send final offer'), findsNothing);
      },
    );
  });
}
