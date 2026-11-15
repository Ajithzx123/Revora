import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/customer/domain/entities/sell_offer.dart';
import 'package:revora/modules/customer/domain/repositories/sell_repository.dart';
import 'package:revora/modules/customer/presentation/ui/listing_details_screen.dart';

/// Regression: on a 375px phone the offer card's buttons were squeezed into a sliver of stacked
/// letters. The screen sweep missed it because it shrinks text to 0.55x. These tests measure the
/// primary button directly and also render at larger text sizes (the test font is about twice as
/// wide as the real one, so 0.8 here is about 145% real text and 1.1 about 200%).
SellOffer offer({List<OfferRound> rounds = const [], String? finalStatus}) =>
    SellOffer(
      id: 'SELL-301-o1',
      dealerId: 'd1',
      dealerName: 'City Pre-owned',
      listingId: 'SELL-301',
      price: 700000,
      status: finalStatus == null ? 'PENDING' : 'ACCEPTED',
      validUntil: DateTime.now().add(const Duration(hours: 30)),
      createdAt: DateTime.now(),
      rounds: rounds,
      finalStatus: finalStatus,
      finalPrice: finalStatus == null ? null : 640000,
      finalDropPercent: finalStatus == null ? null : 8.6,
      finalReasonCode: finalStatus == null ? null : 'MECHANICAL_ISSUE',
      finalEvidence: finalStatus == null
          ? const []
          : const ['https://files.example/report.pdf'],
    );

OfferRound dealerRound() => OfferRound(
  id: 'r1',
  roundNo: 1,
  by: 'DEALER',
  price: 690000,
  status: 'OPEN',
  validUntil: DateTime.now().add(const Duration(hours: 20)),
);

void main() {
  const phone = Size(375, 812);
  final states = <String, SellOffer>{
    'a live offer': offer(),
    "the dealer's counter": offer(rounds: [dealerRound()]),
    'a lowered final price': offer(finalStatus: 'SUBMITTED'),
  };
  final primary = <String, String>{
    'a live offer': 'Accept offer',
    "the dealer's counter": 'Take ',
    'a lowered final price': 'Accept ₹',
  };

  for (final scale in [0.55, 0.8, 1.1]) {
    for (final e in states.entries) {
      testWidgets('${e.key} fits a phone at text scale $scale', (tester) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = MockSellRepository()..seedOffer(e.value);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sellRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const ListingDetailsScreen(listingId: 'SELL-301'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // The primary button must be a real button, not a sliver.
        final button = find
            .ancestor(
              of: find.textContaining(primary[e.key]!).first,
              matching: find.byType(FilledButton),
            )
            .first;
        await tester.ensureVisible(button);
        final size = tester.getSize(button);
        expect(
          size.width,
          greaterThan(140),
          reason: 'the primary button is squeezed to ${size.width}px',
        );
        expect(
          size.height,
          lessThan(80),
          reason: 'its label wraps one letter per line',
        );
      });
    }
  }
}
