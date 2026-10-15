import 'package:cashflow/app/app.dart';
import 'package:cashflow/core/config/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('app starts and uses the flavor name as title', (tester) async {
    FlavorConfig.init(Flavor.dev);
    await tester.pumpWidget(const ProviderScope(child: CashFlowApp()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'CashFlow Dev');
    expect(tester.takeException(), isNull);
  });
}
