import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import 'bill_labels.dart';

/// Add bill step 2 / Edit bill (FR-B6, screen 20): name, customer ID, "Comes every N months",
/// next due date with a preview of the dates after it, usual amount, Remind me.
class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.type = 'other', this.name, this.gap, this.billId});

  final String type;
  final String? name;
  final int? gap;
  final String? billId;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  late String _type = widget.type;
  late final _name = TextEditingController(text: widget.name ?? '');
  final _customer = TextEditingController();
  late int _every = widget.gap ?? 1;
  LocalDate? _due;
  String _usual = '';
  bool _padOpen = false;
  final Set<int> _remind = {3};
  bool _tried = false;

  bool get _editing => widget.billId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else {
      // New bills start from Settings › Default reminder (FR-R2).
      ref.read(profileRepositoryProvider).current().then((p) {
        if (mounted && p != null) {
          setState(() => _remind
            ..clear()
            ..add(p.defaultReminderDays));
        }
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _customer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await ref.read(billRepositoryProvider).byId(widget.billId!);
    if (b == null || !mounted) return;
    setState(() {
      _type = b.billType;
      _name.text = b.name;
      _customer.text = b.customerId ?? '';
      _every = b.everyMonths;
      _due = LocalDate.parse(b.nextDueDate);
      _usual = b.usualAmount == null ? '' : AmountTyping.fromPaise(b.usualAmount!);
      _remind
        ..clear()
        ..addAll((b.reminderDays ?? '').split(',').where((s) => s.isNotEmpty).map(int.parse));
    });
  }

  Future<void> _save() async {
    final due = _due;
    if (due == null) {
      setState(() {
        _tried = true;
        _padOpen = false;
      });
      return;
    }
    final l = context.l10n;
    final name = _name.text.trim().isEmpty ? l.billTypeBill(billTypeName(l, _type)) : _name.text;
    final draft = BillDraft(
      type: _type,
      name: name,
      customerId: _customer.text,
      everyMonths: _every,
      nextDue: due,
      usualAmount: Money.parse(_usual),
      reminderDays: (_remind.toList()..sort()),
    );
    final repo = ref.read(billRepositoryProvider);
    if (_editing) {
      await repo.update(widget.billId!, draft);
    } else {
      await repo.add(draft);
    }
    if (mounted) context.pop();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final start = _due ?? Ist.today();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(start.year, start.month, start.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _due = LocalDate(d.year, d.month, d.day));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (fg, bg) = billColors(context, _type);
    final due = _due;
    final preview = due == null ? null : [for (var i = 1; i <= 3; i++) shortDate(context, due.addMonths(_every * i))].join(', ');

    return AppPage(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              HeaderButton(icon: LucideIcons.chevronLeft, tooltip: l.back, onTap: () => context.pop()),
              Expanded(child: Center(child: Text(_editing ? l.editBill : l.addBill, style: t.titleLarge))),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              // Type + name with "Change" (back to the type list), screen 20 step 2.
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(children: [
                  IconTile(icon: billIcon(_type), color: fg, tint: bg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.billTypeBill(billTypeName(l, _type)), style: t.labelSmall),
                      TextField(
                        controller: _name,
                        onTap: () => setState(() => _padOpen = false),
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration.collapsed(hintText: l.billNameHint),
                      ),
                    ]),
                  ),
                  if (!_editing)
                    InkWell(
                      onTap: () => context.pushReplacement('/bills/new'),
                      customBorder: AppShapes.squircle(AppRadii.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(AppRadii.pill)),
                        child: Text(l.change, style: t.labelMedium?.copyWith(color: c.brandText, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(children: [
                  IconTile(icon: LucideIcons.idCard, color: c.textSecondary, tint: c.raised, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.customerIdOptional, style: t.labelSmall),
                      TextField(
                        controller: _customer,
                        onTap: () => setState(() => _padOpen = false),
                        style: t.titleSmall,
                        decoration: InputDecoration.collapsed(hintText: l.customerIdHint),
                      ),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 6),
                child: Text(l.comesEvery, style: t.labelMedium?.copyWith(color: c.text)),
              ),
              // Five equal choices in one row.
              Row(children: [
                for (final (i, g) in billGaps.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: AppChip(label: '$g', selected: _every == g, onTap: () => setState(() => _every = g)),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                border: _tried && due == null ? BorderSide(color: c.expense, width: 2) : null,
                onTap: _pickDue,
                child: Row(children: [
                  IconTile(icon: LucideIcons.calendar, color: c.textSecondary, tint: c.raised, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.nextDueDate, style: t.labelSmall),
                      Text(due == null ? l.chooseNextDue : longDate(context, due), style: t.titleSmall),
                    ]),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
                ]),
              ),
              if (preview != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                  child: Row(children: [
                    Icon(LucideIcons.repeat, size: 14, color: c.brandText),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l.thenDates(preview), style: t.labelMedium?.copyWith(color: c.brandText))),
                  ]),
                ),
              if (_tried && due == null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(l.chooseNextDue, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                border: _padOpen ? BorderSide(color: c.brandButton, width: 2) : null,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _padOpen = true);
                },
                child: Row(children: [
                  IconTile(icon: LucideIcons.indianRupee, color: c.textSecondary, tint: c.raised, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.usualAmountOptional, style: t.labelSmall),
                      Text('₹${Money.formatTyping(_usual)}', style: t.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 6),
                child: Text(l.remindMe, style: t.labelMedium?.copyWith(color: c.text)),
              ),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final d in const [0, 3, 7])
                  AppChip(
                    label: d == 0 ? l.onDueDay : l.daysBefore(d),
                    selected: _remind.contains(d),
                    onTap: () => setState(() => _remind.contains(d) ? _remind.remove(d) : _remind.add(d)),
                  ),
              ]),
            ]),
          ),
          if (_padOpen)
            Material(
              color: c.sheet,
              shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Padding(padding: const EdgeInsets.only(left: 6), child: Text(l.usualAmountOptional, style: t.labelMedium)),
                    const Spacer(),
                    AppButton(label: l.done, onPressed: () => setState(() => _padOpen = false), expand: false, height: 40),
                  ]),
                  const SizedBox(height: 8),
                  NumberPad(
                    keyHeight: MediaQuery.sizeOf(context).height < 700 ? 42 : 50,
                    onDigit: (d) => setState(() => _usual = AmountTyping.press(_usual, d)),
                    onBackspace: () => setState(() => _usual = AmountTyping.backspace(_usual)),
                  ),
                ]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: AppButton(label: l.saveBill, onPressed: _save),
            ),
        ]),
      ),
    );
  }
}
