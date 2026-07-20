import 'package:flutter_test/flutter_test.dart';
import 'package:bananachock/main.dart';

void main() {
  testWidgets('App should show the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BananachockApp());
    await tester.pump();

    expect(find.text('Bananachock'), findsOneWidget);
    expect(find.text('时间监控与管理'), findsOneWidget);
  });
}