import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revora/modules/admin/domain/entities/admin_ops.dart';
import 'package:revora/modules/admin/domain/repositories/admin_ops_repository.dart';
import 'package:revora/modules/admin/presentation/ui/admin_dashboard_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_requirements_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_vehicles_screen.dart';

/// The admin overview must show what the server counted, never invented numbers.
class FakeAdminOps extends MockAdminOpsRepository {
  Object? failWith;
  AdminKpis kpiValues = const AdminKpis(
    activeDealers: 11,
    pendingDealerApplications: 4,
    openRequirements: 23,
    openListings: 5,
    activeVehicles: 40,
    dealsLast30Days: 6,
    dealValueLast30Days: 4150000,
  );
  bool empty = false;

  @override
  Future<AdminKpis> kpis() async {
    if (failWith != null) throw failWith!;
    return kpiValues;
  }

  @override
  Future<Paged<AdminRequirementRow>> requirements({
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    if (failWith != null) throw failWith!;
    return empty
        ? const Paged(items: [], total: 0)
        : super.requirements(status: status, limit: limit, offset: offset);
  }

  @override
  Future<Paged<AdminVehicleRow>> vehicles({
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    if (failWith != null) throw failWith!;
    return empty
        ? const Paged(items: [], total: 0)
        : super.vehicles(status: status, limit: limit, offset: offset);
  }
}

Widget app(Widget home, FakeAdminOps repo) => ProviderScope(
  key:
      UniqueKey(), // a fresh container each time, so cached providers cannot leak between steps
  overrides: [adminOpsRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(home: home),
);

void bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(1280, 1800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  test(
    'KPIs parse the metrics response and default missing fields to zero',
    () {
      final k = AdminKpis.fromJson({
        'active_dealers': 3,
        'pending_dealer_applications': 1,
        'open_requirements': 9,
        'deal_value_last_30_days': 1030000,
      });
      expect(k.activeDealers, 3);
      expect(k.dealValueLast30Days, 1030000);
      expect(k.activeVehicles, 0); // an older server without the field
      expect(humanizeAction('DEALER_SUSPENDED'), 'Dealer Suspended');
    },
  );

  testWidgets('the overview shows the numbers the server returned', (
    tester,
  ) async {
    bigScreen(tester);
    await tester.pumpWidget(app(const AdminDashboardScreen(), FakeAdminOps()));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget); // verified dealers
    expect(find.text('23'), findsOneWidget); // open requirements
    expect(
      find.textContaining('41.50 Lakh'),
      findsOneWidget,
    ); // deal value, formatted in the UI only
    expect(find.text('6 deals'), findsOneWidget);
    // The old demo trends are gone.
    expect(find.textContaining('this month'), findsNothing);
    expect(find.textContaining('today'), findsNothing);
    expect(
      find.text('Dealer Suspended'),
      findsOneWidget,
    ); // the activity trail is the real audit log
  });

  testWidgets('a failing server shows an error with retry, not demo numbers', (
    tester,
  ) async {
    bigScreen(tester);
    final repo = FakeAdminOps()..failWith = StateError('offline');
    await tester.pumpWidget(app(const AdminDashboardScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load the numbers'), findsOneWidget);
    expect(find.text('11'), findsNothing);
    expect(find.text('—'), findsWidgets);

    repo.failWith = null;
    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load the numbers'), findsNothing);
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('requirements: rows, empty and error states', (tester) async {
    bigScreen(tester);
    final repo = FakeAdminOps();
    await tester.pumpWidget(app(const AdminRequirementsScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('Hyundai i20'), findsOneWidget);
    expect(find.text('Rahul Verma'), findsOneWidget);
    expect(find.text('1 total'), findsOneWidget);

    repo.empty = true;
    await tester.pumpWidget(
      app(const AdminRequirementsScreen(), repo..empty = true),
    );
    await tester.pumpAndSettle();
    expect(find.text('No requirements yet'), findsOneWidget);

    repo.failWith = StateError('offline');
    await tester.pumpWidget(
      app(AdminRequirementsScreen(key: UniqueKey()), repo),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'vehicles: rows without any private price, empty and error states',
    (tester) async {
      bigScreen(tester);
      final repo = FakeAdminOps();
      await tester.pumpWidget(app(const AdminVehiclesScreen(), repo));
      await tester.pumpAndSettle();
      expect(find.text('2021 Hyundai Creta SX(O)'), findsOneWidget);
      expect(find.text('KA01AB1234'), findsOneWidget);
      expect(find.textContaining('minimum'), findsNothing);

      repo.empty = true;
      await tester.pumpWidget(app(AdminVehiclesScreen(key: UniqueKey()), repo));
      await tester.pumpAndSettle();
      expect(find.text('No cars listed yet'), findsOneWidget);

      repo.failWith = StateError('offline');
      await tester.pumpWidget(app(AdminVehiclesScreen(key: UniqueKey()), repo));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    },
  );
}
