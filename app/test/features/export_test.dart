import 'dart:typed_data';

import 'package:cashflow/core/files.dart';
import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/repositories/entry_repository.dart';
import 'package:cashflow/data/repositories/export_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/plan_repository.dart';
import 'package:cashflow/features/export/export_builder.dart';
import 'package:cashflow/l10n/app_localizations.dart';
import 'package:cashflow/shared/widgets/basics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _FakeFiles extends FileService {
  final saved = <(String, String, Uint8List)>[];

  @override
  Future<String> saveToDownloads(String name, String mime, Uint8List bytes) async {
    saved.add((name, mime, bytes));
    return 'content://downloads/1';
  }

  @override
  Future<void> open(String uri, String mime) async {}

  @override
  Future<void> share(String uri, String mime) async {}
}

void main() {
  late Harness h;

  setUp(() async {
    h = Harness();
    await h.init();
  });
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('PDF report: A4 pages drawn by Flutter, Hindi included (FR-C2)', (tester) async {
    await tester.runAsync(() async {
      final l = lookupAppLocalizations(const Locale('hi'));
      final rows = [
        for (var i = 0; i < 30; i++)
          ExportRow(group: ExportGroup.incomeExpense, kind: ExportKind.expense, at: DateTime.utc(2026, 10, 1 + i % 28), amount: 12400, paymentMode: 'cash', title: 'किराना'),
      ];
      final (bytes, pages) = await buildPdf(rows, ExportNames(l: l, locale: const Locale('hi'), categories: const {}, people: const {}),
          from: const LocalDate(2026, 10, 1), to: const LocalDate(2026, 10, 31));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(pages, 2); // 12 rows under the summary + 18 on page 2
    });
  });

  testWidgets('Premium: Export from Settings, CSV of this month saved to Downloads; result sheet shows the file', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await EntryRepository(LocalWriter(h.db, userId: Harness.userId))
        .add(EntryDraft(kind: 'expense', amount: 124000, paymentMode: 'cash', occurredAt: DateTime.now(), title: 'Dinner'));
    final files = _FakeFiles();
    h.extraOverrides = [fileServiceProvider.overrideWithValue(files)];
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);
    await tester.tap(find.text('Export data'));
    await settle(tester);
    expect(find.text('1 entry'), findsOneWidget); // Income & expenses count
    await tester.tap(find.text('CSV'));
    await settle(tester);
    await tester.tap(find.text('Export CSV · 1 entry'));
    await settle(tester);
    expect(files.saved.single.$1, endsWith('.csv'));
    expect(files.saved.single.$2, 'text/csv');
    expect(find.text('Report ready'), findsOneWidget);
    expect(find.text('Saved in Downloads'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Export: nothing included → red message, no file', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    final files = _FakeFiles();
    h.extraOverrides = [fileServiceProvider.overrideWithValue(files)];
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);
    await tester.tap(find.text('Export data'));
    await settle(tester);
    final toggles = find.byType(AppToggle);
    for (var i = 0; i < 3; i++) {
      await tester.tap(toggles.at(i));
      await tester.pump();
    }
    await tester.tap(find.textContaining('Export PDF'));
    await settle(tester);
    expect(find.text('Choose at least one thing to include'), findsOneWidget);
    expect(files.saved, isEmpty);
    await closeApp(tester);
  });
}
