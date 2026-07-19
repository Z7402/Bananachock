import 'package:flutter_test/flutter_test.dart';
import 'package:bananachock/main.dart';

void main() {
  testWidgets('App should build without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BananachockApp());
    expect(find.text('计时'), findsWidgets);
  });
}