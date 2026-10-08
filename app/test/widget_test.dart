import 'package:cashflow/app/app.dart';
import 'package:cashflow/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dev flavor shows CashFlow Dev', (tester) async {
    FlavorConfig.init(Flavor.dev);
    await tester.pumpWidget(const CashFlowApp());
    expect(find.text('CashFlow Dev'), findsOneWidget);
    expect(find.text('Flavor: dev'), findsOneWidget);
  });

  testWidgets('prod flavor shows CashFlow', (tester) async {
    FlavorConfig.init(Flavor.prod);
    await tester.pumpWidget(const CashFlowApp());
    expect(find.text('CashFlow'), findsOneWidget);
    expect(find.text('Flavor: prod'), findsOneWidget);
  });
}
