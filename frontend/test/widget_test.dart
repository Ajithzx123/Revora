import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revora/app.dart';
import 'package:revora/core/utils/storage_helper.dart';

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    await StorageHelper.init();
  });

  testWidgets('Revora smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RevoraApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(RevoraApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
