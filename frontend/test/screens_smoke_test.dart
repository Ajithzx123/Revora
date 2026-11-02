import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revora/core/theme/app_theme.dart';
import 'package:revora/core/utils/storage_helper.dart';
import 'package:revora/modules/admin/presentation/ui/admin_dashboard_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_dealer_detail_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_dealer_verification_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_requirements_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_shell.dart';
import 'package:revora/modules/admin/presentation/ui/admin_vehicles_screen.dart';
import 'package:revora/modules/auth/presentation/ui/login_screen.dart';
import 'package:revora/modules/auth/presentation/ui/register_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_activity_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_buy_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_home_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_profile_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_sell_screen.dart';
import 'package:revora/modules/customer/presentation/ui/customer_shell.dart';
import 'package:revora/modules/customer/presentation/ui/post_buy_requirement_screen.dart';
import 'package:revora/modules/customer/presentation/ui/requirement_details_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/add_car_to_inventory_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_activity_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_application_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_home_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_inventory_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_leads_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_profile_screen.dart';
import 'package:revora/modules/dealer/presentation/ui/dealer_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every main screen in debug mode (where Flutter's layout assertions are on)
/// at phone, tablet and desktop sizes. A layout error, overflow or unbounded-height
/// mistake fails the test instead of surprising someone running `flutter run`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  const sizes = {
    'phone': Size(390, 844),
    'tablet': Size(800, 1100),
    'desktop': Size(1280, 800),
  };

  final screens = <String, Widget Function()>{
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'customer shell': () => const CustomerShell(),
    'customer home': () => const CustomerHomeScreen(),
    'customer buy': () => const CustomerBuyScreen(),
    'customer sell': () => const CustomerSellScreen(),
    'customer activity': () => const CustomerActivityScreen(),
    'customer profile': () => const CustomerProfileScreen(),
    'request details': () => const RequirementDetailsScreen(requirementId: 'REQ-101'),
    'post request': () => const PostBuyRequirementScreen(),
    'dealer shell': () => const DealerShell(),
    'dealer home': () => const DealerHomeScreen(),
    'dealer leads': () => const DealerLeadsScreen(),
    'dealer inventory': () => const DealerInventoryScreen(),
    'dealer activity': () => const DealerActivityScreen(),
    'dealer profile': () => const DealerProfileScreen(),
    'add car': () => const AddCarToInventoryScreen(),
    'dealer application': () => const DealerApplicationScreen(),
    'admin shell': () => const AdminShell(),
    'admin dashboard': () => const AdminDashboardScreen(),
    'admin dealer queue': () => const AdminDealerVerificationScreen(),
    'admin dealer detail': () => const AdminDealerDetailScreen(dealerId: 'd1'),
    'admin requirements': () => const AdminRequirementsScreen(),
    'admin vehicles': () => const AdminVehiclesScreen(),
  };

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets('${screen.key} renders without layout errors on ${size.key}', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            // Tests draw every letter as a full-width square (the "Ahem" font), so text is
            // about twice as wide as in the real app. Scale it down to real-font widths so
            // only genuine layout mistakes fail, not that artefact.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.55)),
              child: child!,
            ),
            home: screen.value(),
          ),
        ));
        // Let futures resolve and entrance animations play without waiting on
        // endless spinners.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
