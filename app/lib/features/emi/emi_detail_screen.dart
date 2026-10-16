import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/emi_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import 'emi_bills_screen.dart';
import 'mark_paid_sheet.dart';

/// EMI detail (FR-E10, screen 19): hero, facts, installments (earlier paid collapsed, last paid,
/// next due with Mark paid, upcoming dimmed). Opens scrolled to the due one.
class EmiDetailScreen extends ConsumerStatefulWidget {
  const EmiDetailScreen({super.key, required this.emiId});

  final String emiId;

  @override
  ConsumerState<EmiDetailScreen> createState() => _EmiDetailScreenState();
}

class _EmiDetailScreenState extends ConsumerState<EmiDetailScreen> {
  final _dueKey = GlobalKey();
  bool _expanded = false;
  bool _scrolled = false;

  void _scrollToDue() {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dueKey.currentContext;
      if (ctx == null) return;
      // Only scrolls when the due one is below the screen, so the top card stays when it fits.
      Scrollable.ensureVisible(ctx, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd, duration: const Duration(milliseconds: 300));
    });
  }

  Future<void> _delete(EmiLoan emi) async {
    final l = context.l10n;
    final ok = await showAppSheet<bool>(
      context,
      builder: (context) {
        final c = context.colors;
        final t = Theme.of(context).textTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon: LucideIcons.trash2, color: c.expense, tint: c.expenseTint, size: 56),
            const SizedBox(height: AppSpacing.sm),
            Text(l.deleteEmiTitle, textAlign: TextAlign.center, style: t.titleLarge),
            const SizedBox(height: 6),
            Text(
              l.deleteEmiBody,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(label: l.cancel, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context, false)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(label: l.delete, kind: AppButtonKind.danger, onPressed: () => Navigator.pop(context, true)),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await ref.read(emiRepositoryProvider).delete(emi.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final repo = ref.watch(emiRepositoryProvider);
    return AppPage(
      child: SafeArea(
        child: StreamBuilder<EmiWithInstallments?>(
          stream: repo.watchOne(widget.emiId),
          builder: (context, snap) {
            final item = snap.data;
            if (item == null) return const SizedBox.shrink();
            final e = item.emi;
            final paid = item.installments.where((i) => i.status == 'paid').toList();
            final upcoming = item.installments.where((i) => i.status != 'paid').toList();
            final earlier = paid.length > 1 ? paid.sublist(0, paid.length - 1) : const <EmiInstallment>[];
            final lastPaid = item.lastPaid;
            final next = item.nextDue;
            _scrollToDue();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      HeaderButton(icon: LucideIcons.chevronLeft, tooltip: l.back, onTap: () => context.pop()),
                      Expanded(
                        child: Column(
                          children: [
                            Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleLarge),
                            if (e.lender != null) Text(e.lender!, style: t.bodySmall),
                          ],
                        ),
                      ),
                      PopupMenuButton<int>(
                        tooltip: l.more,
                        color: c.sheet,
                        child: HeaderButton(icon: LucideIcons.ellipsis, tooltip: l.more),
                        onSelected: (v) => v == 0 ? context.push('/emi/${e.id}/edit') : _delete(e),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 0, child: Text(l.editEmi)),
                          PopupMenuItem(
                            value: 1,
                            child: Text(l.deleteEmi, style: TextStyle(color: c.expense)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      _Hero(item: item),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _FactBox(label: l.emiLabel, value: Money.format(e.emiAmount)),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _FactBox(label: l.loanLabel, value: Money.format(e.loanAmount)),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _FactBox(label: l.interestLabel, value: '${rateText(e.rateBp)}% · ${Money.format(item.totalInterest)}'),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, AppSpacing.md, 4, AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(child: Text(l.installments, style: t.labelMedium)),
                            if (paid.isNotEmpty)
                              InkWell(
                                onTap: earlier.isEmpty ? null : () => setState(() => _expanded = !_expanded),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(l.paidCountLabel(paid.length), style: t.labelMedium),
                                    Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: c.textSecondary),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (earlier.isNotEmpty && !_expanded)
                        _Row(
                          dashed: true,
                          leading: const _Check(),
                          title: l.earlierPaid(earlier.length),
                          subtitle:
                              '${shortDate(context, LocalDate.parse(earlier.first.dueDate))} – ${shortDate(context, LocalDate.parse(earlier.last.dueDate))} · '
                              '${Money.format(earlier.fold(0, (a, i) => a + i.amount))}',
                          trailing: Icon(LucideIcons.chevronRight, color: c.textMuted),
                          onTap: () => setState(() => _expanded = true),
                        ),
                      if (_expanded)
                        for (final i in earlier) _paidRow(context, item, i),
                      if (lastPaid != null) _paidRow(context, item, lastPaid),
                      for (final i in upcoming) i.id == next?.id ? _dueRow(context, item, i) : _upcomingRow(context, item, i),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _paidRow(BuildContext context, EmiWithInstallments item, EmiInstallment i) {
    final l = context.l10n;
    final c = context.colors;
    final due = LocalDate.parse(i.dueDate);
    final paidOn = i.paidAt == null ? due : Ist.dateOf(i.paidAt!);
    return _Row(
      leading: const _Check(),
      title: longDate(context, due),
      subtitle: paidOn == due ? l.paidOnTime : l.paidOnDate(shortDate(context, paidOn)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountText(Money.format(i.amount), size: 14, alignment: Alignment.centerRight),
          EmiTag(text: l.paid, color: c.income, tint: c.incomeTint),
        ],
      ),
      onTap: () => showPaidInstallmentSheet(context, ref, installment: i, canUndo: item.lastPaid?.id == i.id),
    );
  }

  Widget _dueRow(BuildContext context, EmiWithInstallments item, EmiInstallment i) {
    final l = context.l10n;
    final c = context.colors;
    return Padding(
      key: _dueKey,
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        radius: AppRadii.lg,
        padding: const EdgeInsets.all(14),
        border: BorderSide(color: c.dueSoon.withValues(alpha: 0.45), width: 1.5),
        child: Column(
          children: [
            _rowContent(context, item, i, due: true),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l.markPaid,
              icon: LucideIcons.check,
              kind: AppButtonKind.success,
              height: 46,
              onPressed: () => showMarkPaidSheet(context, emi: item.emi, installment: i, total: item.total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingRow(BuildContext context, EmiWithInstallments item, EmiInstallment i) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(radius: AppRadii.lg, padding: const EdgeInsets.all(14), child: _rowContent(context, item, i)),
  );

  Widget _rowContent(BuildContext context, EmiWithInstallments item, EmiInstallment i, {bool due = false}) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: due ? c.dueSoonTint : c.raised,
            border: due ? Border.all(color: c.dueSoon.withValues(alpha: 0.5)) : null,
          ),
          child: Text(
            '${i.seq}',
            style: t.labelMedium?.copyWith(color: due ? c.dueSoon : c.textSecondary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(longDate(context, LocalDate.parse(i.dueDate)), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(l.inclInterest(Money.format(i.interestPart)), style: t.bodySmall),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountText(Money.format(i.amount), size: 14, alignment: Alignment.centerRight),
            if (due) ...[const SizedBox(height: 3), dueTag(context, LocalDate.parse(i.dueDate), next: true)],
            if (!due && i.seq == item.total) EmiTag(text: l.lastTag, color: c.textSecondary, tint: c.raised),
          ],
        ),
      ],
    );
  }
}

/// Filled green circle with a white tick (paid installments, screen 19).
class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.incomeButton),
      child: Icon(LucideIcons.check, size: 18, color: c.onButton),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.item});

  final EmiWithInstallments item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final closed = item.closed;
    final on = c.onButton;
    final end = item.lastDue;
    final color = closed ? c.incomeButton : c.brandButton;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: AppShapes.squircle(AppRadii.lg),
        shadows: dark ? null : [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(closed ? l.emiClosed : l.remainingToPay, style: t.bodySmall?.copyWith(color: on.withValues(alpha: 0.9))),
                      const SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: ref.watch(emiRepositoryProvider).watchRemaining(item.emi.id),
                        builder: (context, snap) => AmountText(Money.format(snap.data ?? 0), size: 30, color: on),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: ShapeDecoration(color: on.withValues(alpha: 0.18), shape: AppShapes.squircle(AppRadii.sm)),
                  child: Icon(emiIcon(item.emi.icon), color: on, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: item.total == 0 ? 0 : item.paidCount / item.total,
                minHeight: 6,
                color: on,
                backgroundColor: on.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.paidOfTotal(item.paidCount, item.total),
                          style: t.bodySmall?.copyWith(color: on, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' · ${l.leftCount(item.total - item.paidCount)}',
                          style: t.bodySmall?.copyWith(color: on.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(l.endsMonth(monthShort(context, end.year, end.month)), style: t.bodySmall?.copyWith(color: on.withValues(alpha: 0.9))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FactBox extends StatelessWidget {
  const _FactBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall),
          AmountText(value, size: 13.5),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, required this.subtitle, required this.trailing, required this.onTap, this.dashed = false});

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  /// The collapsed "earlier paid" row has a dashed outline on a lighter fill (screen 19).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final row = Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
            ],
          ),
        ),
        trailing,
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: dashed
          ? DashedOutline(
              color: c.border,
              radius: AppRadii.lg,
              child: Material(
                color: c.card.withValues(alpha: 0.5),
                shape: AppShapes.squircle(AppRadii.lg),
                child: InkWell(
                  onTap: onTap,
                  customBorder: AppShapes.squircle(AppRadii.lg),
                  child: Padding(padding: const EdgeInsets.all(14), child: row),
                ),
              ),
            )
          : AppCard(radius: AppRadii.lg, padding: const EdgeInsets.all(14), onTap: onTap, child: row),
    );
  }
}
