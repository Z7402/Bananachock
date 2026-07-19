import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananachock/main.dart';

void main() {
  testWidgets('App should build without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('zh_CN');

    await tester.pumpWidget(
      const ProviderScope(
        child: BananachockApp(),
      ),
    );

    // The app starts on a two-second splash screen, followed by a
    // 600-millisecond fade transition to MainScreen.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('计时'), findsWidgets);
  });
}
