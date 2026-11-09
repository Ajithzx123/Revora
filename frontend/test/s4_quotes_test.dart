import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/customer/domain/entities/quote.dart';
import 'package:revora/modules/customer/domain/repositories/quotes_repository.dart';
import 'package:revora/modules/customer/presentation/widgets/customer_quote_card.dart';
import 'package:revora/modules/customer/presentation/widgets/quote_actions.dart';

Map<String, dynamic> quoteJson({
  String status = 'PENDING',
  List<Map<String, dynamic>> rounds = const [],
}) => {
  'id': 'q1',
  'dealer_id': 'd1',
  'dealer_name': 'Apex Motors',
  'dealer_rating': 4.6,
  'requirement_id': 'r1',
  'quoted_price': 650000,
  'message': 'First owner',
  'status': status,
  'created_at': '2026-11-02T10:00:00',
  'kind': 'SOURCED',
  'revision': 2,
  'valid_until': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 30))
      .toIso8601String(),
  'delivery_days': 7,
  'warranty_months': 6,
  'rounds': rounds,
};

Map<String, dynamic> roundJson(String by) => {
  'id': 'x',
  'round_no': 1,
  'by': by,
  'price': 620000,
  'status': 'OPEN',
  'valid_until': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 5))
      .toIso8601String(),
};

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('quote parses terms, kind, validity and rounds', () {
    final q = Quote.fromJson(quoteJson(rounds: [roundJson('DEALER')]));
    expect(q.kindLabel, 'Will be sourced for you');
    expect(q.deliveryDays, 7);
    expect(q.validityLabel, startsWith('Valid for'));
    expect(q.openRound?.by, 'DEALER');
    expect(q.price, 650000);
  });

  test(
    'mock accept closes the other quotes on the same request and refuses a stale price',
    () async {
      final repo = MockQuotesRepository();
      final list = await repo.forRequirement(
        (await repo.forRequirement('REQ-101')).first.requirementId,
      );
      expect(list.length, greaterThan(1));
      expect(
        () => repo.accept(list.first.id, expectedPrice: 1),
        throwsException,
      );
      await repo.accept(list.first.id, expectedPrice: list.first.price);
      final after = await repo.forRequirement(list.first.requirementId);
      expect(after.where((q) => q.isAccepted), hasLength(1));
      expect(
        after.where((q) => q.status == 'NOT_SELECTED'),
        hasLength(list.length - 1),
      );
    },
  );

  testWidgets('open quote offers Accept deal, Counter and Not interested', (
    tester,
  ) async {
    var accepted = false, countered = false, rejected = false;
    await tester.pumpWidget(
      host(
        CustomerQuoteCard(
          quote: Quote.fromJson(quoteJson()),
          onAccept: () => accepted = true,
          onCounter: () => countered = true,
          onReject: () => rejected = true,
        ),
      ),
    );
    expect(find.text('Delivery in 7d'), findsOneWidget);
    await tester.tap(find.text('Accept deal'));
    await tester.tap(find.text('Counter'));
    await tester.tap(find.text('Not interested'));
    expect([accepted, countered, rejected], [true, true, true]);
  });

  testWidgets(
    "a dealer's counter replaces Accept with Take, and a closed quote has no buttons",
    (tester) async {
      await tester.pumpWidget(
        host(
          CustomerQuoteCard(
            quote: Quote.fromJson(quoteJson(rounds: [roundJson('DEALER')])),
            onTakeCounter: () {},
            onDeclineCounter: () {},
          ),
        ),
      );
      expect(find.textContaining('Take'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Accept deal'), findsNothing);

      await tester.pumpWidget(
        host(
          CustomerQuoteCard(
            quote: Quote.fromJson(quoteJson(status: 'NOT_SELECTED')),
          ),
        ),
      );
      expect(find.text('Accept deal'), findsNothing);
      expect(find.text('NOT SELECTED'), findsOneWidget);
    },
  );

  testWidgets(
    'accepting asks first, then calls the repository with the price the buyer saw',
    (tester) async {
      final repo = MockQuotesRepository();
      final quote = (await repo.forRequirement('REQ-101')).first;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quotesRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => QuoteActions(context, ref).accept(quote),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Every other quote'), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(
        (await repo.forRequirement('REQ-101')).any((q) => q.isAccepted),
        isFalse,
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept deal'));
      await tester.pumpAndSettle();
      expect(
        (await repo.forRequirement('REQ-101')).where((q) => q.isAccepted),
        hasLength(1),
      );
    },
  );
}
