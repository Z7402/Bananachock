import 'package:bananachock/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App should show the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BananachockApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Bananachock'), findsOneWidget);
    expect(find.text('时间监控与管理'), findsOneWidget);
  });
}