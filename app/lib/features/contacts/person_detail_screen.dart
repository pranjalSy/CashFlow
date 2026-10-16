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
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/overlays.dart';
import 'contacts_controller.dart';
import 'repayment_sheet.dart';

/// Person detail (FR-D8, screen 14): net card, Lent / Borrowed / Repayment, history.
/// Works for a saved person or a phone contact that has no udhar yet.
class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.person});

  final PersonRef person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = person.id;
    final saved = id == null ? null : ref.watch(peopleByIdProvider).value?[id];
    final name = saved?.name ?? person.name;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    return AppPage(
      child: SafeArea(
        child: id == null
            ? _body(context, ref, name, const [], premium)
            : StreamBuilder<List<DebtWithPayments>>(
                stream: ref.watch(debtRepositoryProvider).watchPerson(id),
                builder: (context, snap) => _body(context, ref, name, snap.data ?? const [], premium),
              ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, String name, List<DebtWithPayments> debts, bool premium) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    var lent = 0, repaidToYou = 0, borrowed = 0, repaidByYou = 0;
    for (final d in debts) {
      if (d.lent) {
        lent += d.debt.amount;
        repaidToYou += d.repaid;
      } else {
        borrowed += d.debt.amount;
        repaidByYou += d.repaid;
      }
    }
    final net = (lent - repaidToYou) - (borrowed - repaidByYou);
    final first = name.split(' ').first;
    final open = debts.where((d) => d.remaining > 0).toList();

    void addUdhar(String direction) {
      final q = {...person.toQuery(), 'direction': direction, 'name': name, 'person': ?person.id};
      context.push(Uri(path: '/udhar/new', queryParameters: q).toString());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xl),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(LucideIcons.arrowLeft, color: c.text),
              tooltip: l.back,
            ),
            const Spacer(),
          ],
        ),
        Center(
          child: PersonAvatar(name: name, color: c.lent, tint: c.lentTint, size: 76, circle: true),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(name, textAlign: TextAlign.center, style: t.headlineSmall),
        ),
        if (person.phone != null)
          Center(
            child: Text(person.phone!, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: net > 0 ? c.lent : (net < 0 ? c.borrowed : c.card),
          radius: AppRadii.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                net > 0 ? l.owesYou(first) : (net < 0 ? l.youOwe(first) : l.allClear),
                style: t.bodyMedium?.copyWith(color: net == 0 ? c.textSecondary : c.onButton.withValues(alpha: 0.9)),
              ),
              AmountText(Money.format(net.abs()), size: 32, color: net == 0 ? c.text : c.onButton),
              if (lent > 0)
                Text(
                  l.lentRepaid(Money.format(lent), Money.format(repaidToYou)),
                  style: t.bodySmall?.copyWith(color: net == 0 ? c.textSecondary : c.onButton.withValues(alpha: 0.85)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionTile(icon: LucideIcons.arrowRight, label: l.lent, color: c.lent, onTap: () => addUdhar('lent')),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ActionTile(icon: LucideIcons.arrowLeft, label: l.borrowed, color: c.borrowed, onTap: () => addUdhar('borrowed')),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ActionTile(
                icon: LucideIcons.refreshCw,
                label: l.repayment,
                color: c.income,
                onTap: open.isEmpty
                    ? () => CompactSnackbar.show(context, message: l.allClear)
                    : () => showRepaymentSheet(context, personName: first, debts: open, premium: premium),
              ),
            ),
          ],
        ),
        SectionLabel(l.history),
        if (debts.isEmpty)
          AppCard(
            child: EmptyState(icon: LucideIcons.handshake, title: l.noUdharTitle(first), message: l.noUdharBody),
          ),
        for (final (i, d) in debts.indexed)
          FadeSlideIn(
            key: ValueKey(d.debt.id),
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _DebtCard(
                item: d,
                premium: premium,
                onAddExtra: () => ref.read(debtRepositoryProvider).addExtraAsDebt(d.debt.id, premium: premium),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.item, required this.premium, required this.onAddExtra});

  final DebtWithPayments item;
  final bool premium;
  final VoidCallback onAddExtra;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final d = item.debt;
    final lent = item.lent;
    final color = lent ? c.lent : c.borrowed;
    final settled = item.remaining <= 0;
    final progress = d.amount == 0 ? 0.0 : (item.repaid / d.amount).clamp(0.0, 1.0);
    final day = Ist.dateOf(d.occurredAt);
    final meta = '${shortDate(context, day)} · ${paymentLabel(l, d.paymentMode, d.onlineMethod)}${d.note == null ? '' : ' · ${d.note}'}';
    Widget? tag;
    if (settled) {
      tag = _Tag(text: l.settled, color: c.income, tint: c.incomeTint, icon: LucideIcons.check);
    } else if (premium && d.dueDate != null) {
      final days = Ist.today().daysUntil(LocalDate.parse(d.dueDate!));
      tag = days < 0
          ? _Tag(text: l.overdueDays(-days), color: c.expense, tint: c.expenseTint, icon: LucideIcons.clock)
          : _Tag(text: l.dueInDays(days), color: c.dueSoon, tint: c.dueSoonTint, icon: LucideIcons.calendar);
    }
    final extra = d.extraNotAdded;
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: lent ? LucideIcons.arrowRight : LucideIcons.arrowLeft, color: color, tint: lent ? c.lentTint : c.borrowedTint),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${lent ? l.lent : l.borrowed} ${Money.format(d.amount)}', style: t.titleSmall),
                    Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                  ],
                ),
              ),
              ?tag,
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 6, color: settled ? c.incomeButton : color, backgroundColor: c.raised),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(l.repaidOf(Money.format(item.repaid), Money.format(d.amount)), style: t.bodySmall)),
              if (!settled) Text(l.amountLeft(Money.format(item.remaining)), style: t.labelMedium?.copyWith(color: c.text)),
            ],
          ),
          for (final p in item.payments) ...[
            Divider(height: 18, color: c.border),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: lent ? c.income : c.expense),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lent ? l.repaymentReceived : l.repaymentPaid, style: t.titleSmall),
                      Text('${shortDate(context, Ist.dateOf(p.occurredAt))} · ${paymentLabel(l, p.paymentMode, p.onlineMethod)}', style: t.bodySmall),
                    ],
                  ),
                ),
                AmountText('${lent ? '+' : Money.minus}${Money.format(p.amount)}', color: lent ? c.income : c.expense, alignment: Alignment.centerRight),
              ],
            ),
          ],
          if (extra != null && extra > 0) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onAddExtra,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  lent ? l.extraNotAddedBorrowed(Money.format(extra)) : l.extraNotAddedLent(Money.format(extra)),
                  style: t.labelMedium?.copyWith(color: c.brandText, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, required this.tint, required this.icon});

  final String text;
  final Color color;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
