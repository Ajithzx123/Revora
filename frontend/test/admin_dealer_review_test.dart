import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revora/modules/admin/data/repositories/mock_admin_dealer_review_repository.dart';
import 'package:revora/modules/admin/domain/repositories/admin_dealer_review_repository.dart';
import 'package:revora/modules/admin/presentation/ui/admin_dealer_verification_screen.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_application.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('MockAdminDealerReviewRepository', () {
    test('cannot approve until every required document is accepted', () async {
      final repo = MockAdminDealerReviewRepository();
      await expectLater(repo.approve('d1'), throwsException);
      final app = await repo.detail('d1');
      for (final doc in app.documents) {
        await repo.reviewDocument('d1', doc.id, accept: true);
      }
      await repo.approve('d1');
      expect((await repo.detail('d1')).status, DealerStatus.approved);
    });

    test('rejecting a document needs a note; invalid moves are refused', () async {
      final repo = MockAdminDealerReviewRepository();
      final doc = (await repo.detail('d1')).documents.first;
      await expectLater(repo.reviewDocument('d1', doc.id, accept: false), throwsException);
      await expectLater(repo.suspend('d1', 'x'), throwsException); // pending -> suspended
      await expectLater(repo.reactivate('d3'), throwsException); // approved -> approved
    });

    test('list filters by status', () async {
      final repo = MockAdminDealerReviewRepository();
      expect(await repo.list(status: DealerStatus.pending), hasLength(2));
      expect(await repo.list(), hasLength(3));
    });
  });

  testWidgets('admin reviews documents, then approves', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminDealerReviewRepositoryProvider.overrideWithValue(MockAdminDealerReviewRepository()),
      ],
      child: const MaterialApp(home: AdminDealerVerificationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Apex Motor Corp'), findsOneWidget);
    expect(find.text('Sunrise Cars'), findsOneWidget);
    expect(find.text('City Wheels'), findsNothing); // approved, hidden by the Pending filter

    await tester.tap(find.text('Apex Motor Corp'));
    await tester.pumpAndSettle();

    FilledButton approve() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Approve dealer'));
    expect(approve().onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Accept').at(i));
      await tester.pumpAndSettle();
    }
    expect(approve().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve dealer'));
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Suspend dealer'), findsOneWidget);
  });
}
