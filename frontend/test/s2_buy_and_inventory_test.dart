import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revora/modules/customer/data/repositories/mock_requirement_repository.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/customer/domain/entities/requirement_draft.dart';
import 'package:revora/modules/customer/domain/repositories/requirement_repository.dart';
import 'package:revora/modules/customer/presentation/providers/requirements_provider.dart';
import 'package:revora/modules/customer/presentation/ui/post_buy_requirement_screen.dart';
import 'package:revora/modules/dealer/data/repositories/mock_inventory_repository.dart';
import 'package:revora/modules/dealer/domain/entities/buy_lead.dart';
import 'package:revora/modules/dealer/domain/entities/vehicle_draft.dart';
import 'package:revora/modules/dealer/domain/repositories/inventory_repository.dart';
import 'package:revora/modules/dealer/presentation/providers/inventory_provider.dart';
import 'package:revora/modules/dealer/presentation/ui/add_car_to_inventory_screen.dart';

RequirementDraft _draft({String make = 'Hyundai', String? model = 'i20', int budgetMax = 700000, String city = 'Bengaluru'}) =>
    RequirementDraft(make: make, model: model, yearMin: 2021, budgetMax: budgetMax, city: city);

VehicleDraft _car(String reg) => VehicleDraft(
      registrationNo: reg,
      make: 'Hyundai',
      model: 'i20',
      year: 2021,
      fuel: 'Petrol',
      transmission: 'Manual',
      km: 20000,
      price: 650000,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('BuyRequirement', () {
    final json = {
      'id': 'abc',
      'make': 'Hyundai',
      'model': null,
      'year_min': 2021,
      'year_max': null,
      'budget_min': 500000,
      'budget_max': 700000,
      'fuel': null,
      'transmission': 'Automatic',
      'city': 'Bengaluru',
      'radius_km': 100,
      'urgency': 'NOW',
      'needs_finance': true,
      'must_have': ['transmission'],
      'status': 'PAUSED',
      'quote_count': 2,
      'created_at': '2026-11-01T10:00:00',
      'expires_at': '2026-11-15T10:00:00',
    };

    test('parses the API response, treating nulls as "any"', () {
      final r = BuyRequirement.fromJson(json);
      expect(r.model, '');
      expect(r.fuelType, 'Any');
      expect(r.transmission, 'Automatic');
      expect(r.isPaused, isTrue);
      expect(r.isEditable, isTrue);
      expect(r.title, '2021+ Hyundai');
      expect(r.urgencyLabel, 'Needs it now');
      expect(r.mustHave, ['transmission']);
      expect(r.quotesReceived, 2);
    });

    test('a draft built from a request sends nulls for "any" so edits can clear fields', () {
      final body = RequirementDraft.from(BuyRequirement.fromJson(json)).toJson();
      expect(body['model'], isNull);
      expect(body['fuel'], isNull);
      expect(body['year_max'], isNull);
      expect(body['transmission'], 'Automatic');
      expect(body['must_have'], ['transmission']);
    });
  });

  group('MockRequirementRepository', () {
    test('create, edit, pause, resume and close follow the same rules as the API', () async {
      final repo = MockRequirementRepository();
      final created = await repo.create(_draft(budgetMax: 800000));
      expect(created.isOpen, isTrue);

      final edited = await repo.update(created.id, _draft(budgetMax: 900000));
      expect(edited.maxBudget, 900000);

      expect((await repo.pause(created.id)).isPaused, isTrue);
      await expectLater(repo.pause(created.id), throwsException);
      expect((await repo.resume(created.id)).isOpen, isTrue);

      final closed = await repo.cancel(created.id);
      expect(closed.status, 'cancelled');
      await expectLater(repo.update(created.id, _draft()), throwsException);
      await expectLater(repo.resume(created.id), throwsException);
    });

    test('stops at five open requests', () async {
      final repo = MockRequirementRepository();
      final open = (await repo.list()).where((r) => r.isEditable).length;
      for (var i = open; i < 5; i++) {
        await repo.create(_draft(budgetMax: 600000 + i * 10000));
      }
      await expectLater(repo.create(_draft(budgetMax: 999999)), throwsException);
    });
  });

  group('MockInventoryRepository', () {
    test('rejects a registration number that is already listed, however it is spelled', () async {
      final repo = MockInventoryRepository();
      await repo.create(_car('KA01AB1234'));
      await expectLater(repo.create(_car('ka01 ab-1234')), throwsException);
    });

    test('photos can be added, made the cover and removed; at most eight', () async {
      final repo = MockInventoryRepository();
      var car = await repo.create(_car('KA01AB9999'));
      for (var i = 0; i < 3; i++) {
        car = await repo.addPhoto(car.id, fileName: 'p$i.jpg', bytes: Uint8List(4));
      }
      expect(car.images, hasLength(3));
      final third = car.images[2].id;
      car = await repo.reorderPhotos(car.id, [third, car.images[0].id, car.images[1].id]);
      expect(car.images.first.id, third);
      expect(car.imageUrl, car.images.first.url);
      car = await repo.removePhoto(car.id, third);
      expect(car.images, hasLength(2));

      for (var i = 0; i < 6; i++) {
        car = await repo.addPhoto(car.id, fileName: 'x.jpg', bytes: Uint8List(4));
      }
      await expectLater(repo.addPhoto(car.id, fileName: 'x.jpg', bytes: Uint8List(4)), throwsException);
    });

    test('marking a car sold keeps it in the list but unavailable', () async {
      final repo = MockInventoryRepository();
      final car = await repo.create(_car('KA01AB7777'));
      final sold = await repo.setStatus(car.id, 'sold');
      expect(sold.isSold, isTrue);
      expect(sold.isAvailable, isFalse);
      expect((await repo.list()).any((v) => v.id == car.id), isTrue);
    });
  });

  group('BuyLead.fromJson', () {
    test('uses first name only and hides the match badge until matching exists', () {
      final lead = BuyLead.fromJson({
        'id': 'l1',
        'buyer_first_name': 'Rahul',
        'city': 'Mumbai',
        'make': 'Kia',
        'model': 'Seltos',
        'year_min': 2021,
        'year_max': null,
        'budget_min': 0,
        'budget_max': 1500000,
        'urgency': 'WITHIN_60_DAYS',
        'must_have': ['fuel'],
        'created_at': '2026-11-01T10:00:00',
        'quote_count': 1,
      });
      expect(lead.customerName, 'Rahul');
      expect(lead.matchPercentage, 0);
      expect(lead.fuelType, 'Any');
      expect(lead.urgencyLabel, 'In 30-60 days');
      expect(lead.title, '2021+ Kia Seltos');
    });
  });

  group('Post-request form', () {
    Future<ProviderContainer> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [requirementRepositoryProvider.overrideWithValue(MockRequirementRepository())],
        child: const MaterialApp(home: PostBuyRequirementScreen()),
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(PostBuyRequirementScreen)));
    }

    testWidgets('walks the three steps, enforces required fields, and posts the request', (tester) async {
      final container = await pumpForm(tester);
      final before = (await container.read(requirementsProvider.future)).length;

      // Step 1 needs a make.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a make to continue.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hyundai').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 needs a city.
      expect(find.text('How much, and where?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your city to continue.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bengaluru').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: review, then post.
      expect(find.text('Check and post'), findsOneWidget);
      expect(find.text('YOUR REQUEST'), findsOneWidget);
      expect(find.textContaining('Hyundai'), findsWidgets);

      await tester.tap(find.text('Post request'));
      await tester.pumpAndSettle();

      final after = container.read(requirementsProvider).valueOrNull!;
      expect(after.length, before + 1);
      expect(after.first.make, 'Hyundai');
      expect(after.first.preferredCity, 'Bengaluru');
      expect(after.first.isOpen, isTrue);
    });

    testWidgets('editing pre-fills the form and saves the change', (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = MockRequirementRepository();
      final existing = await repo.create(_draft(budgetMax: 800000));
      await tester.pumpWidget(ProviderScope(
        overrides: [requirementRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: PostBuyRequirementScreen(existing: existing)),
      ));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(PostBuyRequirementScreen)));

      expect(find.text('Edit request'), findsOneWidget);
      expect(find.text('Hyundai'), findsWidgets); // make is already chosen
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      final saved = container.read(requirementsProvider).valueOrNull!.firstWhere((r) => r.id == existing.id);
      expect(saved.make, 'Hyundai');
    });
  });

  group('Add-car form', () {
    testWidgets('shows what is missing and does not create a car', (tester) async {
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = MockInventoryRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: AddCarToInventoryScreen()),
      ));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(AddCarToInventoryScreen)));
      final before = (await container.read(inventoryProvider.future)).length;

      await tester.tap(find.text('Add car'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the registration number'), findsOneWidget);
      expect(find.text('Enter the kilometres driven'), findsOneWidget);
      expect(find.text('Enter the asking price'), findsOneWidget);
      expect(find.text('Choose the make.'), findsOneWidget);
      expect((await container.read(inventoryProvider.future)).length, before);
    });

    testWidgets('rejects a registration number that is not shaped like one', (tester) async {
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(MockInventoryRepository())],
        child: const MaterialApp(home: AddCarToInventoryScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Registration number'), 'HELLO');
      await tester.tap(find.text('Add car'));
      await tester.pumpAndSettle();
      expect(find.text('That does not look like a registration number'), findsOneWidget);
    });
  });
}
