import 'dart:ui';

import 'package:cashflow/core/config/flavor.dart';
import 'package:cashflow/core/theme/app_theme.dart';
import 'package:cashflow/features/dev/gallery_screen.dart';
import 'package:cashflow/shared/widgets/amount_text.dart';
import 'package:cashflow/shared/widgets/app_button.dart';
import 'package:cashflow/shared/widgets/app_card.dart';
import 'package:cashflow/shared/widgets/glass.dart';
import 'package:cashflow/shared/widgets/glass_nav_bar.dart';
import 'package:cashflow/shared/widgets/number_pad.dart';
import 'package:cashflow/shared/widgets/overlays.dart';
import 'package:cashflow/shared/widgets/swipe_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light, List<dynamic> overrides = const [], double textScale = 1}) {
  return ProviderScope(
    overrides: [...overrides],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale), size: const Size(360, 780)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('is at least 48 dp tall and always tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(AppButton(label: 'Save', onPressed: () => taps++, height: 40)));
      expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });
  });

  group('AmountText', () {
    testWidgets('never wraps or overflows in a narrow box at 2x text', (tester) async {
      await tester.pumpWidget(host(
        const SizedBox(width: 90, child: AmountText('₹1,20,00,000.50', size: 36)),
        textScale: 2,
      ));
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text('₹1,20,00,000.50'));
      expect(text.maxLines, 1);
      expect(tester.getSize(find.byType(AmountText)).width, lessThanOrEqualTo(90));
    });
  });

  group('Glass cards', () {
    bool hasBlur(WidgetTester tester) => find.byType(BackdropFilter).evaluate().isNotEmpty;

    testWidgets('light mode cards are solid', (tester) async {
      await tester.pumpWidget(host(const AppCard(child: Text('x'))));
      expect(hasBlur(tester), isFalse);
    });

    testWidgets('dark mode cards are frosted glass', (tester) async {
      await tester.pumpWidget(host(const AppCard(child: Text('x')), brightness: Brightness.dark));
      expect(hasBlur(tester), isTrue);
    });

    testWidgets('"Reduce glass effects" makes dark cards solid', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [reduceGlassProvider.overrideWith(_ReduceOn.new)],
        child: MaterialApp(theme: AppTheme.dark(), home: const Scaffold(body: AppCard(child: Text('x')))),
      ));
      expect(hasBlur(tester), isFalse);
    });

    testWidgets('bottom bar is glass in light mode too', (tester) async {
      await tester.pumpWidget(host(GlassNavBar(
        items: const [
          NavItem(icon: Icons.home_rounded, label: 'Home'),
          NavItem(icon: Icons.people_alt_rounded, label: 'Contacts'),
          NavItem(icon: Icons.pie_chart_rounded, label: 'Charts'),
          NavItem(icon: Icons.calendar_month_rounded, label: 'EMI'),
        ],
        index: 0,
        onTap: (_) {},
        onPlus: () {},
        plusLabel: 'Add',
      )));
      expect(find.byWidgetPredicate((w) => w is BackdropFilter && w.filter is ImageFilter), findsOneWidget);
    });
  });

  group('GlassNavBar', () {
    testWidgets('shows only the active tab name and reports taps', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(host(GlassNavBar(
        items: const [
          NavItem(icon: Icons.home_rounded, label: 'Home'),
          NavItem(icon: Icons.people_alt_rounded, label: 'Contacts'),
          NavItem(icon: Icons.pie_chart_rounded, label: 'Charts'),
          NavItem(icon: Icons.calendar_month_rounded, label: 'EMI'),
        ],
        index: 0,
        onTap: (i) => tapped = i,
        onPlus: () {},
        plusLabel: 'Add',
      )));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Charts'), findsNothing);
      await tester.tap(find.byIcon(Icons.pie_chart_rounded));
      expect(tapped, 2);
    });

    const tabs = [
      NavItem(icon: Icons.home_rounded, label: 'Home'),
      NavItem(icon: Icons.people_alt_rounded, label: 'Contacts'),
      NavItem(icon: Icons.pie_chart_rounded, label: 'Charts'),
      NavItem(icon: Icons.calendar_month_rounded, label: 'EMI'),
    ];

    Widget bar({required ValueNotifier<int> index, bool noMotion = false, double width = 360, double textScale = 1}) => MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 780), disableAnimations: noMotion, textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: width,
                  child: ValueListenableBuilder<int>(
                    valueListenable: index,
                    builder: (_, i, _) => GlassNavBar(items: tabs, index: i, onTap: (n) => index.value = n, onPlus: () {}, plusLabel: 'Add'),
                  ),
                ),
              ),
            ),
          ),
        );

    // The selection pill is the first Positioned in the tab stack.
    double pillLeft(WidgetTester tester) =>
        tester.widget<Positioned>(find.descendant(of: find.byType(GlassNavBar), matching: find.byType(Positioned)).first).left!;

    testWidgets('the pill slides through the tabs in between and ends on the tapped tab', (tester) async {
      final index = ValueNotifier(0);
      await tester.pumpWidget(ProviderScope(child: bar(index: index)));
      final start = pillLeft(tester);
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final mid = pillLeft(tester);
      await tester.pumpAndSettle();
      final end = pillLeft(tester);
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
      expect(find.text('EMI'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('tabs in between are not affected: they never grow or show their name (owner bug, 16 Oct)', (tester) async {
      final index = ValueNotifier(0);
      await tester.pumpWidget(ProviderScope(child: bar(index: index)));
      double width(IconData icon) => tester.getSize(find.ancestor(of: find.byIcon(icon), matching: find.byType(Positioned)).first).width;
      final contacts = width(Icons.people_alt_rounded);
      final charts = width(Icons.pie_chart_rounded);
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 45));
        expect(find.text('Contacts'), findsNothing);
        expect(find.text('Charts'), findsNothing);
        expect(width(Icons.people_alt_rounded), contacts);
        expect(width(Icons.pie_chart_rounded), charts);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('with "remove animations" the pill jumps', (tester) async {
      final index = ValueNotifier(0);
      await tester.pumpWidget(ProviderScope(child: bar(index: index, noMotion: true)));
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pump();
      final now = pillLeft(tester);
      await tester.pumpAndSettle();
      expect(pillLeft(tester), now);
    });

    testWidgets('no overflow on a 320 px phone at 2.0× text, while moving too', (tester) async {
      final index = ValueNotifier(0);
      await tester.pumpWidget(ProviderScope(child: bar(index: index, width: 320, textScale: 2)));
      await tester.tap(find.byIcon(Icons.people_alt_rounded));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // Phone test (16 Oct): TalkBack could not see the snackbar action or a button inside a card.
  group('TalkBack', () {
    testWidgets('snackbar is a live region and its action is a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(builder: (c) => TextButton(onPressed: () => CompactSnackbar.show(c, message: 'Deleted', actionLabel: 'Undo', onAction: () {}), child: const Text('go'))),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(tester.getSemantics(find.text('Undo')), matchesSemantics(label: 'Undo', isButton: true, isFocusable: true, hasTapAction: true, hasFocusAction: true));
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      handle.dispose();
    });

    testWidgets('a button inside a card is its own button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(AppCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Installment 5'), AppButton(label: 'Mark paid', onPressed: () {})]))));
      final node = tester.getSemantics(find.text('Mark paid'));
      expect(node.label, 'Mark paid');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('NumberPad', () {
    testWidgets('sends digits, dot and backspace', (tester) async {
      final keys = <String>[];
      var back = 0;
      await tester.pumpWidget(host(SizedBox(width: 320, child: NumberPad(onDigit: keys.add, onBackspace: () => back++))));
      await tester.tap(find.text('4'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('.'));
      await tester.tap(find.bySemanticsLabel('Backspace'));
      expect(keys, ['4', '5', '.']);
      expect(back, 1);
    });
  });

  group('SwipeActionRow', () {
    Widget row(VoidCallback onDelete) => SizedBox(
          width: 340,
          child: SwipeActionRow(
            editLabel: 'Edit',
            deleteLabel: 'Delete',
            onEdit: () {},
            onDelete: onDelete,
            child: const SizedBox(height: 64, child: ColoredBox(color: Colors.white, child: Center(child: Text('Groceries')))),
          ),
        );

    testWidgets('full swipe past 60% asks to delete', (tester) async {
      var asked = 0;
      await tester.pumpWidget(host(row(() => asked++)));
      await tester.drag(find.text('Groceries'), const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(asked, 1);
    });

    testWidgets('short swipe only reveals the buttons', (tester) async {
      var asked = 0;
      await tester.pumpWidget(host(row(() => asked++)));
      await tester.drag(find.text('Groceries'), const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(asked, 0);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('gallery renders on a small phone (${mode.name})', (tester) async {
      FlavorConfig.init(Flavor.dev);
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: mode, home: const GalleryScreen()),
      ));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Hindi / Gujarati'), 400, scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });
  }
}

class _ReduceOn extends ReduceGlass {
  @override
  bool build() => true;
}
