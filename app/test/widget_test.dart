import 'package:cashflow/core/config/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/harness.dart';

void main() {
  test('dev flavor is named CashFlow Dev', () {
    FlavorConfig.init(Flavor.dev);
    expect(FlavorConfig.instance.appName, 'CashFlow Dev');
    expect(FlavorConfig.instance.isDev, isTrue);
  });

  test('prod flavor is named CashFlow', () {
    FlavorConfig.init(Flavor.prod);
    expect(FlavorConfig.instance.appName, 'CashFlow');
    expect(FlavorConfig.instance.isDev, isFalse);
  });

  testWidgets('app starts on the splash and uses the flavor name as title', (tester) async {
    final h = Harness();
    await h.init();
    await tester.pumpWidget(h.app());
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'CashFlow Dev');
    expect(find.text('Track every rupee'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await closeApp(tester);
    await h.dispose();
  });
}
