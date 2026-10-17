import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/files.dart';
import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/export_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import '../emi/emi_lock.dart';
import 'export_builder.dart';

enum _Range { thisMonth, lastMonth, threeMonths, thisYear, custom }

/// Export (FR-C2, screen 22), from Settings only: PDF or CSV, a date range, what to include with
/// counts. The file is made on the phone and saved to Downloads; then Open or Share.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _pdf = true;
  _Range _range = _Range.thisMonth;
  (LocalDate, LocalDate)? _custom;
  final Set<ExportGroup> _include = {...ExportGroup.values};
  List<ExportRow>? _rows;
  bool _busy = false;
  bool _tried = false;

  (LocalDate, LocalDate) get _dates {
    final t = Ist.today();
    final first = LocalDate(t.year, t.month, 1);
    LocalDate end(LocalDate m) => LocalDate(m.year, m.month, LocalDate.daysInMonth(m.year, m.month));
    return switch (_range) {
      _Range.thisMonth => (first, end(first)),
      _Range.lastMonth => (first.addMonths(-1), end(first.addMonths(-1))),
      _Range.threeMonths => (first.addMonths(-2), end(first)),
      _Range.thisYear => (LocalDate(t.year, 1, 1), LocalDate(t.year, 12, 31)),
      _Range.custom => _custom ?? (first, t),
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (from, to) = _dates;
    final rows = await ref.read(exportRepositoryProvider).rows(from, to);
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: now);
    if (r == null) return;
    setState(() {
      _range = _Range.custom;
      _custom = (LocalDate(r.start.year, r.start.month, r.start.day), LocalDate(r.end.year, r.end.month, r.end.day));
    });
    _load();
  }

  List<ExportRow> get _chosen => (_rows ?? const <ExportRow>[]).where((r) => _include.contains(r.group)).toList();

  Future<void> _export() async {
    if (_busy) return;
    if (_include.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    final l = context.l10n;
    final locale = ref.read(localeProvider) ?? Localizations.localeOf(context);
    final names = ExportNames(
      l: l,
      locale: locale,
      categories: ref.read(categoriesByIdProvider).value ?? const {},
      people: ref.read(peopleByIdProvider).value ?? const {},
    );
    final (from, to) = _dates;
    final rows = _chosen;
    try {
      final Uint8List bytes;
      int? pages;
      if (_pdf) {
        final (b, p) = await buildPdf(rows, names, from: from, to: to);
        bytes = b;
        pages = p;
      } else {
        bytes = buildCsv(rows, names);
      }
      final name = 'CashFlow_${from.toIso()}_${to.toIso()}.${_pdf ? 'pdf' : 'csv'}';
      final mime = _pdf ? 'application/pdf' : 'text/csv';
      final uri = await ref.read(fileServiceProvider).saveToDownloads(name, mime, bytes);
      if (!mounted) return;
      setState(() => _busy = false);
      await _showResult(name, mime, uri, bytes.length, pages);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      CompactSnackbar.show(context, message: l.exportFailed);
    }
  }

  Future<void> _showResult(String name, String mime, String uri, int size, int? pages) {
    final files = ref.read(fileServiceProvider);
    final kb = size < 1024 * 1024 ? '${(size / 1024).ceil()} KB' : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return showAppSheet<void>(context, builder: (context) {
      final l = context.l10n;
      final c = context.colors;
      final t = Theme.of(context).textTheme;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: IconTile(icon: LucideIcons.fileCheck, color: c.income, tint: c.incomeTint, size: 56)),
        const SizedBox(height: AppSpacing.sm),
        Text(l.reportReady, textAlign: TextAlign.center, style: t.titleLarge),
        Text(pages == null ? l.fileInfoCsv(name, kb) : l.fileInfoPdf(name, pages, kb), textAlign: TextAlign.center, style: t.bodySmall),
        Text(l.savedInDownloads, textAlign: TextAlign.center, style: t.labelMedium?.copyWith(color: c.income)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: AppButton(label: l.openLabel, icon: LucideIcons.externalLink, kind: AppButtonKind.secondary, onPressed: () => files.open(uri, mime))),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: AppButton(label: l.shareLabel, icon: LucideIcons.share2, onPressed: () => files.share(uri, mime))),
        ]),
        const SizedBox(height: 6),
        Text(l.shareHint, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final (from, to) = _dates;
    final rows = _rows ?? const <ExportRow>[];
    int count(ExportGroup g) => rows.where((r) => r.group == g).length;
    final total = _chosen.length;

    Widget formatCard(bool pdf, String title, String sub, IconData icon, Color color, Color tint) {
      final on = _pdf == pdf;
      return Expanded(
        child: AppCard(
          radius: AppRadii.lg,
          padding: const EdgeInsets.all(14),
          border: BorderSide(color: on ? c.brandButton : c.border, width: on ? 1.6 : 1),
          onTap: () => setState(() => _pdf = pdf),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconTile(icon: icon, color: color, tint: tint, size: 40),
              const Spacer(),
              if (on)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandButton),
                  child: Icon(LucideIcons.check, size: 14, color: c.onButton),
                ),
            ]),
            const SizedBox(height: 10),
            Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(sub, maxLines: 2, style: t.bodySmall),
          ]),
        ),
      );
    }

    Widget include(ExportGroup g, String title, String counts) {
      final on = _include.contains(g);
      return InkWell(
        onTap: () => setState(() => on ? _include.remove(g) : _include.add(g)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall),
                Text(counts, style: t.bodySmall),
              ]),
            ),
            Semantics(
              checked: on,
              label: title,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 26,
                height: 26,
                decoration: ShapeDecoration(
                  color: on ? c.brandButton : c.card,
                  shape: AppShapes.squircle(8, side: BorderSide(color: on ? c.brandButton : c.border, width: 1.5)),
                ),
                child: on ? Icon(LucideIcons.check, size: 16, color: c.onButton) : null,
              ),
            ),
          ]),
        ),
      );
    }

    return AppPage(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              HeaderButton(icon: LucideIcons.chevronLeft, tooltip: l.back, onTap: () => context.pop()),
              Expanded(child: Center(child: Text(l.exportTitle, style: t.titleLarge))),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              if (!premium)
                const EmiLockCard()
              else ...[
                SectionLabel(l.formatLabel),
                Row(children: [
                  formatCard(true, 'PDF', l.pdfDesc, LucideIcons.fileText, c.expense, c.expenseTint),
                  const SizedBox(width: AppSpacing.xs),
                  formatCard(false, 'CSV', l.csvDesc, LucideIcons.sheet, c.income, c.incomeTint),
                ]),
                SectionLabel(l.dateRange),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final r in _Range.values)
                    AppChip(
                      label: switch (r) {
                        _Range.thisMonth => l.rangeThisMonth,
                        _Range.lastMonth => l.rangeLastMonth,
                        _Range.threeMonths => l.range3Months,
                        _Range.thisYear => l.rangeThisYear,
                        _Range.custom => l.rangeCustom,
                      },
                      selected: _range == r,
                      onTap: () {
                        if (r == _Range.custom) {
                          _pickCustom();
                        } else {
                          setState(() => _range = r);
                          _load();
                        }
                      },
                    ),
                ]),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  radius: AppRadii.lg,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  onTap: _pickCustom,
                  child: Row(children: [
                    Icon(LucideIcons.calendar, size: 18, color: c.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.periodRange(longDate(context, from), longDate(context, to)), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
                  ]),
                ),
                SectionLabel(l.includeLabel),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  border: _tried && _include.isEmpty ? BorderSide(color: c.expense, width: 2) : null,
                  child: Column(children: [
                    include(ExportGroup.incomeExpense, l.incExpLabel, l.entriesN(count(ExportGroup.incomeExpense))),
                    Divider(height: 1, color: c.border),
                    include(ExportGroup.udhar, l.udharLabel, l.entriesN(count(ExportGroup.udhar))),
                    Divider(height: 1, color: c.border),
                    include(ExportGroup.emiBills, l.emiBillsLabel, l.paymentsN(count(ExportGroup.emiBills))),
                  ]),
                ),
                if (_tried && _include.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(l.chooseSomething, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Icon(LucideIcons.lock, size: 14, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l.exportPrivacy, style: t.bodySmall)),
                ]),
              ],
            ]),
          ),
          if (premium)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: AppButton(label: _busy ? l.exportingLabel : l.exportButton(_pdf ? 'PDF' : 'CSV', total), icon: LucideIcons.download, onPressed: _export),
            ),
        ]),
      ),
    );
  }
}
