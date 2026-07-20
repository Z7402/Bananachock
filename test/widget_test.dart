import 'package:bananachock/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });
  testWidgets('App should show the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BananachockApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Bananachock'), findsOneWidget);
    expect(find.text('时间监控与管理'), findsOneWidget);

    // Advance the splash delay and route transition so no timer remains
    // pending when the widget test is torn down.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
  });
}