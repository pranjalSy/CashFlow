import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';
import '../emi/emi_lock.dart';
import 'bill_labels.dart';

/// Add bill, step 1 (FR-B1, screen 20): pick a type, or a popular provider with its gap filled in.
class BillTypeScreen extends ConsumerWidget {
  const BillTypeScreen({super.key});

  void _open(BuildContext context, String type, {String? name, int? gap}) {
    final q = {'type': type, 'name': ?name, 'gap': ?gap?.toString()};
    context.pushReplacement(Uri(path: '/bills/new/form', queryParameters: q).toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    return AppPage(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xl), children: [
          Row(children: [
            IconButton(onPressed: () => context.pop(), icon: Icon(LucideIcons.x, color: c.text), tooltip: l.close),
            Expanded(child: Center(child: Text(l.addBill, style: t.titleLarge))),
            const SizedBox(width: 48),
          ]),
          if (!premium)
            const Padding(padding: EdgeInsets.only(top: AppSpacing.md), child: EmiLockCard())
          else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l.billWhich, style: t.headlineSmall),
            Text(l.billWhichSub, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 0.82,
              children: [
                for (final (i, type) in billTypes.indexed)
                  FadeSlideIn(
                    index: i,
                    child: AppCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      onTap: () => _open(context, type),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        () {
                          final (fg, bg) = billColors(context, type);
                          return IconTile(icon: billIcon(type), color: fg, tint: bg, size: 40);
                        }(),
                        const SizedBox(height: 6),
                        Text(billTypeName(l, type), maxLines: 2, textAlign: TextAlign.center, style: t.labelMedium?.copyWith(color: c.text)),
                      ]),
                    ),
                  ),
              ],
            ),
            SectionLabel(l.popular),
            for (final p in popularProviders)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  radius: AppRadii.md,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  onTap: () => _open(context, p.type, name: p.name, gap: p.gap),
                  child: ListRowTile(
                    leading: () {
                      final (fg, bg) = billColors(context, p.type);
                      return IconTile(icon: billIcon(p.type), color: fg, tint: bg);
                    }(),
                    title: p.name,
                    subtitle: '${billTypeName(l, p.type)} · ${l.everyNMonths(p.gap)}',
                    trailing: Icon(LucideIcons.chevronRight, color: c.textMuted),
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}
