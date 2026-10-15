import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/entry_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/person_avatar.dart';

/// One Home card: icon, title, "category · payment · time", signed amount (E2).
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.category, this.person, this.hideAmount = false, this.onTap});

  final HomeEntry entry;
  final Category? category;
  final PeopleData? person;
  final bool hideAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final b = Theme.of(context).brightness;
    final t = Theme.of(context).textTheme;
    final pay = paymentLabel(l, entry.paymentMode, entry.onlineMethod);
    final time = timeLabel(context, entry.occurredAt);

    Widget leading;
    String title;
    String meta;
    Color amountColor;
    String sign;
    switch (entry.kind) {
      case EntryKind.income:
      case EntryKind.expense:
        final cat = category;
        final color = cat == null ? c.textSecondary : Color(cat.color);
        leading = IconTile(
          icon: categoryIcon(cat?.icon ?? 'others'),
          color: categoryInk(color, b),
          tint: categoryTint(color, b),
        );
        final catName = cat == null ? l.catOthers : categoryName(l, cat);
        title = entry.title ?? catName;
        meta = '$catName · $pay · $time';
        final income = entry.kind == EntryKind.income;
        amountColor = income ? c.income : c.expense;
        sign = income ? '+' : Money.minus;
      case EntryKind.lent:
      case EntryKind.borrowed:
        final lent = entry.kind == EntryKind.lent;
        final name = person?.name ?? '—';
        leading = PersonAvatar(name: name, color: lent ? c.lent : c.borrowed, tint: lent ? c.lentTint : c.borrowedTint);
        title = name;
        meta = '${lent ? l.lent : l.borrowed} · $pay · $time';
        amountColor = lent ? c.lent : c.borrowed;
        sign = '';
    }
    final amount = hideAmount ? '₹ •••••' : '$sign${Money.format(entry.amount)}';
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(children: [
        leading,
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          ]),
        ),
        const SizedBox(width: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: AmountText(amount, color: amountColor, alignment: Alignment.centerRight),
        ),
      ]),
    );
  }
}
