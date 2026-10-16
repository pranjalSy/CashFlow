import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../core/utils/offscreen.dart';
import '../../data/local/database.dart';
import '../../data/repositories/export_repository.dart';

/// Names needed to describe rows in the user's language.
class ExportNames {
  const ExportNames({required this.l, required this.locale, required this.categories, required this.people});

  final AppLocalizations l;
  final Locale locale;
  final Map<String, Category> categories;
  final Map<String, PeopleData> people;

  String type(ExportKind k) => switch (k) {
        ExportKind.income => l.income,
        ExportKind.expense => l.expense,
        ExportKind.emi => l.emiLabel,
        ExportKind.bill => l.billLabel,
        ExportKind.lent => l.lent,
        ExportKind.borrowed => l.borrowed,
        ExportKind.repaymentIn => l.repaymentReceived,
        ExportKind.repaymentOut => l.repaymentPaid,
      };

  String details(ExportRow r) {
    if (r.personId != null) return people[r.personId]?.name ?? '';
    final cat = r.categoryId == null ? null : categories[r.categoryId];
    final catName = cat == null ? l.catOthers : categoryName(l, cat);
    return r.title == null || r.title!.isEmpty ? catName : '${r.title} · $catName';
  }

  String payment(ExportRow r) => paymentLabel(l, r.paymentMode, r.onlineMethod);
}

/// CSV for Excel / Sheets (FR-C2, TRD 15): UTF-8 with BOM so ₹ and Indian scripts show; plain numbers.
Uint8List buildCsv(List<ExportRow> rows, ExportNames n) {
  String cell(String v) => '"${v.replaceAll('"', '""')}"';
  final l = n.l;
  final b = StringBuffer('﻿')
    ..writeln([l.colDate, l.colType, l.colDetails, l.colPayment, l.colAmount, l.colNote].map(cell).join(','));
  for (final r in rows) {
    final amount = (r.isIn ? r.amount : -r.amount) / 100;
    b.writeln([
      cell(Ist.dateOf(r.at).toIso()),
      cell(n.type(r.kind)),
      cell(n.details(r)),
      cell(n.payment(r)),
      amount.toStringAsFixed(2),
      cell(r.note ?? ''),
    ].join(','));
  }
  return Uint8List.fromList(utf8.encode(b.toString()));
}

/// PDF report (FR-C2, TRD 15): page 1 summary + spending by category, then the entries table.
/// Pages are drawn by Flutter (correct Hindi/Gujarati) and placed in an A4 PDF. Returns bytes and page count.
Future<(Uint8List, int)> buildPdf(List<ExportRow> rows, ExportNames n, {required LocalDate from, required LocalDate to}) async {
  final pages = await renderReportPages(rows, n, from: from, to: to);
  final doc = pw.Document(title: n.l.reportTitle, creator: 'CashFlow');
  for (final png in pages) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(pw.MemoryImage(Uint8List.fromList(png)), fit: pw.BoxFit.fill),
    ));
  }
  return (await doc.save(), pages.length);
}

/// The report pages as PNG images (A4, 2× for sharp print).
Future<List<List<int>>> renderReportPages(List<ExportRow> rows, ExportNames n, {required LocalDate from, required LocalDate to}) async {
  const firstRows = 12;
  const perPage = 26;
  final rest = rows.length > firstRows ? rows.sublist(firstRows) : const <ExportRow>[];
  final pages = 1 + (rest.length / perPage).ceil();
  const size = Size(595, 842); // A4 in points
  return [
    for (var p = 0; p < pages; p++)
      await renderWidgetToPng(
        _PageFrame(
          n: n,
          page: p + 1,
          pages: pages,
          child: p == 0
              ? _SummaryPage(rows: rows, firstRows: rows.take(firstRows).toList(), n: n, from: from, to: to)
              : _Table(rows: rest.skip((p - 1) * perPage).take(perPage).toList(), n: n),
        ),
        size: size,
      ),
  ];
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.n, required this.page, required this.pages, required this.child});

  final ExportNames n;
  final int page;
  final int pages;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Localizations(
        locale: n.locale,
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(builder: (context) {
          final c = context.colors;
          final t = Theme.of(context).textTheme;
          return ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: child),
                Divider(color: c.border),
                Row(children: [
                  Expanded(child: Text(n.l.madeOnPhone, style: t.bodySmall?.copyWith(fontSize: 9))),
                  Text(n.l.pageOf(page, pages), style: t.bodySmall?.copyWith(fontSize: 9)),
                ]),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryPage extends StatelessWidget {
  const _SummaryPage({required this.rows, required this.firstRows, required this.n, required this.from, required this.to});

  final List<ExportRow> rows;
  final List<ExportRow> firstRows;
  final ExportNames n;
  final LocalDate from;
  final LocalDate to;

  @override
  Widget build(BuildContext context) {
    final l = n.l;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    int sum(bool Function(ExportRow) f) => rows.where(f).fold(0, (a, r) => a + r.amount);
    final income = sum((r) => r.kind == ExportKind.income);
    final expense = sum((r) => r.kind == ExportKind.expense || r.kind == ExportKind.emi || r.kind == ExportKind.bill);
    final lent = sum((r) => r.kind == ExportKind.lent);
    final borrowed = sum((r) => r.kind == ExportKind.borrowed);
    final byCat = <String, int>{};
    for (final r in rows.where((r) => r.kind == ExportKind.expense || r.kind == ExportKind.emi || r.kind == ExportKind.bill)) {
      final cat = r.categoryId == null ? null : n.categories[r.categoryId];
      final name = cat == null ? l.catOthers : categoryName(l, cat);
      byCat[name] = (byCat[name] ?? 0) + r.amount;
    }
    final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    Widget stat(String label, int v, Color color) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: t.bodySmall?.copyWith(fontSize: 9)),
              Text(Money.format(v), style: t.titleSmall?.copyWith(color: color, fontSize: 13)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('CashFlow · ${l.reportTitle}', style: t.titleLarge?.copyWith(fontSize: 20)),
      Text(l.periodRange(longDate(context, from), longDate(context, to)), style: t.bodyMedium?.copyWith(color: c.textSecondary)),
      const SizedBox(height: 12),
      Row(children: [stat(l.income, income, c.income), stat(l.expense, expense, c.expense), stat(l.savedLabel, income - expense, income >= expense ? c.income : c.expense)]),
      Row(children: [stat(l.lent, lent, c.lent), stat(l.borrowed, borrowed, c.borrowed), const Expanded(child: SizedBox())]),
      if (cats.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(l.spendingByCategory, style: t.titleSmall),
        const SizedBox(height: 4),
        for (final e in cats.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 120, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(fontSize: 10))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: expense == 0 ? 0 : e.value / expense, minHeight: 6, color: c.expenseButton, backgroundColor: c.raised),
                ),
              ),
              SizedBox(width: 80, child: Text(Money.format(e.value), textAlign: TextAlign.right, style: t.bodySmall?.copyWith(fontSize: 10))),
            ]),
          ),
      ],
      const SizedBox(height: 12),
      Expanded(child: _Table(rows: firstRows, n: n)),
    ]);
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.rows, required this.n});

  final List<ExportRow> rows;
  final ExportNames n;

  @override
  Widget build(BuildContext context) {
    final l = n.l;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final head = t.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: c.textSecondary);
    final cell = t.bodySmall?.copyWith(fontSize: 9.5, color: c.text);
    Widget row(List<Widget> cells) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 62, child: cells[0]),
            SizedBox(width: 92, child: cells[1]),
            Expanded(child: cells[2]),
            SizedBox(width: 70, child: cells[3]),
            SizedBox(width: 78, child: Align(alignment: Alignment.centerRight, child: cells[4])),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      row([Text(l.colDate, style: head), Text(l.colType, style: head), Text(l.colDetails, style: head), Text(l.colPayment, style: head), Text(l.colAmount, style: head)]),
      Divider(height: 1, color: c.border),
      for (final r in rows) ...[
        row([
          Text(shortDate(context, Ist.dateOf(r.at)), style: cell),
          Text(n.type(r.kind), maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
          Text(r.note == null ? n.details(r) : '${n.details(r)} · ${r.note}', maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
          Text(n.payment(r), maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
          Text('${r.isIn ? '+' : Money.minus}${Money.format(r.amount)}', style: cell?.copyWith(color: r.isIn ? c.income : c.expense, fontWeight: FontWeight.w700)),
        ]),
        Divider(height: 1, color: c.border.withValues(alpha: 0.6)),
      ],
    ]);
  }
}
