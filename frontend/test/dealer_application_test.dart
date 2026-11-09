import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revora/core/utils/storage_helper.dart';
import 'package:revora/modules/dealer/data/repositories/mock_dealer_onboarding_repository.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_application.dart';
import 'package:revora/modules/dealer/domain/repositories/dealer_onboarding_repository.dart';
import 'package:revora/modules/dealer/presentation/providers/dealer_application_provider.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_application_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('MockDealerOnboardingRepository', () {
    test('mirrors the backend rules', () async {
      final repo = MockDealerOnboardingRepository();
      var app = await repo.fetch();
      expect(app.status, DealerStatus.draft);
      expect(app.canSubmit, isFalse);
      expect(app.missingDocuments, hasLength(3));

      await expectLater(repo.submit(), throwsException);

      app = await repo.updateDetails(address: '12 MG Road');
      for (final t in [
        DocumentType.ownerId,
        DocumentType.businessProof,
        DocumentType.addressProof,
      ]) {
        app = await repo.uploadDocument(
          t,
          fileName: 'a.jpg',
          bytes: Uint8List(4),
        );
      }
      expect(app.canSubmit, isTrue);

      app = await repo.submit();
      expect(app.status, DealerStatus.pending);
      expect(app.editable, isFalse);
      await expectLater(repo.updateDetails(city: 'Pune'), throwsException);
    });

    test('a newer upload replaces the older one of the same type', () async {
      final repo = MockDealerOnboardingRepository();
      await repo.uploadDocument(
        DocumentType.ownerId,
        fileName: 'one.jpg',
        bytes: Uint8List(1),
      );
      final app = await repo.uploadDocument(
        DocumentType.ownerId,
        fileName: 'two.jpg',
        bytes: Uint8List(1),
      );
      expect(app.documents.map((d) => d.originalName), ['two.jpg']);
    });
  });

  group('DealerApplication.fromJson', () {
    test('parses the API response', () {
      final app = DealerApplication.fromJson({
        'id': 'abc',
        'business_name': 'Apex',
        'city': 'Pune',
        'status': 'NEEDS_CHANGES',
        'status_reason': 'Blurry ID',
        'documents': [
          {
            'id': 'd1',
            'doc_type': 'OWNER_ID',
            'original_name': 'id.jpg',
            'status': 'REJECTED',
            'review_note': 'Unreadable',
          },
        ],
        'missing_documents': ['ADDRESS_PROOF'],
        'can_submit': false,
        'editable': true,
      });
      expect(app.status, DealerStatus.needsChanges);
      expect(
        app.documentOf(DocumentType.ownerId)?.status,
        DocumentStatus.rejected,
      );
      expect(app.documentOf(DocumentType.ownerId)?.reviewNote, 'Unreadable');
      expect(app.missingDocuments, ['ADDRESS_PROOF']);
    });

    test('unknown statuses fall back safely', () {
      expect(DealerStatus.fromApi('SOMETHING_NEW'), DealerStatus.draft);
      expect(DocumentType.fromApi('NOPE'), isNull);
    });
  });

  testWidgets('screen guides the dealer from draft to submitted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockDealerOnboardingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dealerOnboardingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: DealerApplicationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete your application'), findsOneWidget);
    FilledButton submit() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit for review'),
    );
    expect(submit().onPressed, isNull);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DealerApplicationScreen)),
    );
    final notifier = container.read(dealerApplicationProvider.notifier);
    await notifier.saveDetails(
      businessName: 'Demo Motors',
      gstin: '',
      address: '12 MG Road',
      city: 'Bengaluru',
    );
    for (final t in [
      DocumentType.ownerId,
      DocumentType.businessProof,
      DocumentType.addressProof,
    ]) {
      await notifier.upload(t, 'a.jpg', Uint8List(4));
    }
    await tester.pumpAndSettle();
    expect(submit().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit for review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Under review'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Submit for review'),
      findsNothing,
    );
  });
}
