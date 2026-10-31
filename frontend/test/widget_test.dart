import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revora/app.dart';
import 'package:revora/core/utils/storage_helper.dart';
import 'package:revora/modules/auth/presentation/ui/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('signed-out user sees splash, then the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RevoraApp()));

    expect(find.text('Revora'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
