
import 'package:flutter_test/flutter_test.dart';
import 'package:meangreen_marketplace/main.dart';

void main() {
  testWidgets('MeanGreen Marketplace app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MeanGreenApp());

    expect(find.byType(MeanGreenApp), findsOneWidget);
    expect(find.text('MeanGreen Marketplace'), findsOneWidget);
  });
}