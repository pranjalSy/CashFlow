import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/glass.dart';
import '../../shared/widgets/glass_nav_bar.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/plus_menu.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/swipe_row.dart';

/// Dev-only widget gallery (T02) for the owner to approve the shared widgets on a phone.
/// Sample text only; real screens use localized strings.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  int _tab = 0;
  int _segment = 0;
  int _chip = 0;
  bool _toggle = true;
  bool _plusOpen = false;
  String _typed = '2450';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final reduce = ref.watch(reduceGlassProvider);
    return AppPage(
      bottomNavigationBar: GlassNavBar(
        index: _tab,
        onTap: (i) => setState(() => _tab = i),
        onPlus: () => setState(() => _plusOpen = !_plusOpen),
        plusOpen: _plusOpen,
        plusLabel: 'Add',
        items: const [
          NavItem(icon: LucideIcons.house, label: 'Home'),
          NavItem(icon: LucideIcons.users, label: 'Contacts'),
          NavItem(icon: LucideIcons.chartPie, label: 'Charts'),
          NavItem(icon: LucideIcons.calendarDays, label: 'EMI'),
        ],
      ),
      floating: PlusMenu(
        open: _plusOpen,
        onClose: () => setState(() => _plusOpen = false),
        items: [
          PlusMenuItem(label: 'Expense', icon: LucideIcons.arrowUpRight, color: c.expense, tint: c.expenseTint, onTap: () => setState(() => _plusOpen = false)),
          PlusMenuItem(label: 'Income', icon: LucideIcons.arrowDownLeft, color: c.income, tint: c.incomeTint, onTap: () => setState(() => _plusOpen = false)),
          PlusMenuItem(label: 'Lent', icon: LucideIcons.arrowRight, color: c.lent, tint: c.lentTint, onTap: () => setState(() => _plusOpen = false)),
          PlusMenuItem(label: 'Borrowed', icon: LucideIcons.arrowLeft, color: c.borrowed, tint: c.borrowedTint, onTap: () => setState(() => _plusOpen = false)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 140),
          children: [
            Text('Widget gallery', style: t.displaySmall),
            Text('T02 · dev only', style: t.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              child: ListRowTile(
                leading: IconTile(icon: LucideIcons.sparkles, color: c.brandText, tint: c.brandTint, size: 34),
                title: 'Reduce glass effects',
                subtitle: 'Glass → solid surfaces',
                trailing: AppToggle(value: reduce, onChanged: (v) => ref.read(reduceGlassProvider.notifier).set(v)),
              ),
            ),
            const SectionLabel('Summary card'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance at end of October', style: t.labelMedium),
                  AmountText('₹1,20,000', size: 36, color: c.text),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(child: _tile('Income', '+₹45,000', c.income, c.incomeTint, LucideIcons.arrowDownLeft)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _tile('Expense', '−₹28,500', c.expense, c.expenseTint, LucideIcons.arrowUpRight)),
                  ]),
                  const SizedBox(height: AppSpacing.xs),
                  Row(children: [
                    Expanded(child: _tile('Lent', '₹5,000', c.lent, c.lentTint, LucideIcons.arrowRight)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _tile('Borrowed', '₹2,000', c.borrowed, c.borrowedTint, LucideIcons.arrowLeft)),
                  ]),
                ],
              ),
            ),
            const SectionLabel('Entry rows · swipe left'),
            SwipeActionRow(
              editLabel: 'Edit',
              deleteLabel: 'Delete',
              onEdit: () => _snack('Edit tapped'),
              onDelete: _confirmDelete,
              child: _entry(LucideIcons.shoppingCart, 'Groceries', 'Food · UPI · 6:40 PM', '−₹2,450', c.expense, c.expenseTint),
            ),
            const SizedBox(height: AppSpacing.xs),
            SwipeActionRow(
              editLabel: 'Edit',
              deleteLabel: 'Delete',
              onEdit: () => _snack('Edit tapped'),
              onDelete: _confirmDelete,
              child: _entry(LucideIcons.briefcase, 'Salary', 'Salary · Online · 9:15 AM', '+₹45,000', c.income, c.incomeTint),
            ),
            const SectionLabel('Buttons'),
            AppButton(label: 'Save expense', onPressed: () {}, kind: AppButtonKind.danger),
            const SizedBox(height: AppSpacing.xs),
            AppButton(label: 'Mark paid', onPressed: () {}, kind: AppButtonKind.success, icon: LucideIcons.check),
            const SizedBox(height: AppSpacing.xs),
            AppButton(label: 'Save', onPressed: () {}),
            const SizedBox(height: AppSpacing.xs),
            AppButton(label: 'Try Premium · ₹1 for 3 months', onPressed: () {}, kind: AppButtonKind.premium),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Expanded(child: AppButton(label: 'Cancel', onPressed: () {}, kind: AppButtonKind.secondary)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: AppButton(label: 'Remove', onPressed: () {}, kind: AppButtonKind.soft)),
            ]),
            const SectionLabel('Switch, chips, toggle'),
            Center(
              child: SegmentedSwitch(
                options: const ['Expense', 'Income'],
                index: _segment,
                activeColors: [c.expenseButton, c.incomeButton],
                onChanged: (i) => setState(() => _segment = i),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (i, label) in const ['All', 'Expense', 'Income', 'Udhar'].indexed)
                  AppChip(label: label, selected: i == _chip, onTap: () => setState(() => _chip = i)),
              ],
            ),
            Row(children: [Text('Alert me', style: t.titleSmall), const Spacer(), AppToggle(value: _toggle, onChanged: (v) => setState(() => _toggle = v))]),
            const SectionLabel('Number pad'),
            AppCard(
              color: c.sheet,
              child: Column(children: [
                AmountText('₹${Money.formatTyping(_typed)}', size: 40, color: c.expense, alignment: Alignment.center),
                const SizedBox(height: AppSpacing.sm),
                NumberPad(
                  onDigit: (d) => setState(() => _typed = AmountTyping.press(_typed, d)),
                  onBackspace: () => setState(() => _typed = AmountTyping.backspace(_typed)),
                ),
              ]),
            ),
            const SectionLabel('Sheets, popups, snackbar'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              AppButton(label: 'Sheet', expand: false, kind: AppButtonKind.secondary, onPressed: _openSheet),
              AppButton(label: 'Popup', expand: false, kind: AppButtonKind.secondary, onPressed: _openPopup),
              AppButton(label: 'Snackbar', expand: false, kind: AppButtonKind.secondary, onPressed: () => _snack('Installment 5 paid', detail: 'Expense added · 7 left', action: 'Undo')),
            ]),
            const SectionLabel('States'),
            const OfflineBar(text: 'Offline · 2 changes saved on phone'),
            const SizedBox(height: AppSpacing.sm),
            const Center(child: BackOnlineToast(text: 'Back online · all synced')),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: EmptyState(
                icon: LucideIcons.indianRupee,
                title: 'No entries yet',
                message: 'Add your first income or expense.',
                actionLabel: 'Add entry',
                onAction: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumLockCard(
              title: 'Never miss an EMI or bill',
              message: 'Track every installment and get a reminder before the due date.',
              buttonLabel: 'Try Premium · ₹1 for 3 months',
              fineprint: 'Then ₹20/month. Cancel anytime.',
              onTry: () {},
            ),
            const SectionLabel('Hindi / Gujarati'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('हिंदी: उधार दिया · ₹2,450', style: t.bodyLarge),
                Text('ગુજરાતી: ઉધાર આપ્યા · ₹2,450', style: t.bodyLarge),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String amount, Color color, Color tint, IconData icon) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(18)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          IconTile(icon: icon, color: color, tint: context.colors.card.withValues(alpha: 0.6), size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
              AmountText(amount, color: color),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _entry(IconData icon, String title, String meta, String amount, Color color, Color tint) {
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(children: [
        IconTile(icon: icon, color: color, tint: tint),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const SizedBox(width: AppSpacing.xs),
        AmountText(amount, color: color, alignment: Alignment.centerRight),
      ]),
    );
  }

  void _snack(String message, {String? detail, String? action}) {
    CompactSnackbar.show(context, message: message, detail: detail, actionLabel: action, onAction: action == null ? null : () {});
  }

  void _confirmDelete() {
    showAppSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(icon: LucideIcons.trash2, color: context.colors.expense, tint: context.colors.expenseTint, size: 56),
          const SizedBox(height: AppSpacing.sm),
          Text('Delete this entry?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: AppButton(label: 'Cancel', kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Delete',
                kind: AppButtonKind.danger,
                onPressed: () {
                  Navigator.pop(context);
                  _snack('"Groceries" deleted', action: 'Undo');
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _openSheet() {
    showAppSheet<void>(
      context,
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Mark as paid', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AmountText('₹7,996.39', size: 40, color: context.colors.expense, alignment: Alignment.center),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Mark paid', kind: AppButtonKind.success, icon: LucideIcons.check, onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  void _openPopup() {
    showAppPopup<void>(
      context,
      builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
        IconTile(icon: LucideIcons.bike, color: context.colors.brandText, tint: context.colors.brandTint, size: 64),
        const SizedBox(height: AppSpacing.sm),
        Text('EMI due today', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.dueSoon)),
        Text('Bike loan · ₹7,996.39', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: AppButton(label: 'Not yet', kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppButton(label: 'Paid', kind: AppButtonKind.success, icon: LucideIcons.check, onPressed: () => Navigator.pop(context))),
        ]),
      ]),
    );
  }
}
