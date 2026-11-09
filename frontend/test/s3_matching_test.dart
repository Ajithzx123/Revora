import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/dealer/domain/entities/buy_lead.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_application.dart';
import 'package:revora/modules/dealer/presentation/widgets/buy_lead_card.dart';

Map<String, dynamic> leadJson({int tier = 1}) => {
  'id': 'r1',
  'buyer_first_name': 'Asha',
  'city': 'Bengaluru',
  'make': 'Hyundai',
  'model': 'i20',
  'year_min': 2021,
  'budget_max': 700000,
  'created_at': '2026-11-02T10:00:00',
  'match_score': 87,
  'match_tier': tier,
  'match_reasons': ['Exact match in stock: 2021 i20', 'In Bengaluru'],
  'matched_vehicle_title': '2021 Hyundai i20',
  'response_deadline': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 5))
      .toIso8601String(),
};

void main() {
  test('lead parses match fields', () {
    final lead = BuyLead.fromJson(leadJson());
    expect(lead.matchPercentage, 87);
    expect(lead.tierLabel, 'Exact car in your stock');
    expect(lead.matchReasons, hasLength(2));
    expect(lead.deadlineLabel, startsWith('Reply within'));
    expect(
      BuyLead.fromJson(leadJson(tier: 3)).tierLabel,
      'You can source this',
    );
  });

  test(
    'requirement parses dealers_notified and application parses sourcing makes',
    () {
      final req = BuyRequirement.fromJson({
        'id': 'x',
        'make': 'Tata',
        'year_min': 2020,
        'budget_max': 500000,
        'city': 'Pune',
        'created_at': '2026-11-02T10:00:00',
        'dealers_notified': 4,
      });
      expect(req.dealersNotified, 4);
      final app = DealerApplication.fromJson({
        'id': 'd',
        'sourcing_makes': ['Kia', 'Tata'],
      });
      expect(app.sourcingMakes, ['Kia', 'Tata']);
    },
  );

  testWidgets('lead card shows why, tier and the Not for me action', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuyLeadCard(
              lead: BuyLead.fromJson(leadJson()),
              onSendQuote: () {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Exact car in your stock'), findsOneWidget);
    expect(find.text('Exact match in stock: 2021 i20'), findsOneWidget);
    await tester.tap(find.text('Not for me'));
    expect(dismissed, isTrue);
  });
}
