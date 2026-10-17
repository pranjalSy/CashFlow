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
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/payment_picker.dart';
import '../home/delete_entry.dart';
import 'category_picker.dart';

/// Add or edit income / expense on one screen (F1–F5, screen 11).
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key, this.kind = 'expense', this.entryId});

  final String kind;
  final String? entryId;

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  late String _kind = widget.kind;
  String _amount = '';
  bool _padOpen = true;
  Category? _category;
  final _title = TextEditingController();
  final _note = TextEditingController();
  DateTime? _when; // null = "Now"
  String? _mode;
  String? _method;
  bool _tried = false;
  bool _loaded = false;

  bool get _editing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(entryRepositoryProvider);
    if (_editing) {
      final t = await repo.byId(widget.entryId!);
      if (t != null) {
        final cats = await ref.read(categoryRepositoryProvider).watchAll().first;
        _kind = t.kind;
        _amount = AmountTyping.fromPaise(t.amount);
        _category = cats[t.categoryId];
        _title.text = t.title ?? '';
        _note.text = t.note ?? '';
        _when = t.occurredAt;
        _mode = t.paymentMode;
        _method = t.onlineMethod;
        _padOpen = false;
      }
    } else {
      final last = await repo.lastPayment(_kind);
      if (last != null) {
        _mode = last.$1;
        _method = last.$2;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  int? get _paise => Money.parse(_amount);

  Future<void> _save() async {
    final amount = _paise;
    if (amount == null || amount <= 0 || _mode == null) {
      setState(() => _tried = true);
      return;
    }
    final draft = EntryDraft(
      kind: _kind,
      amount: amount,
      paymentMode: _mode!,
      onlineMethod: _method,
      occurredAt: (_when ?? DateTime.now()).toUtc(),
      categoryId: _category?.id,
      title: _title.text,
      note: _note.text,
    );
    final repo = ref.read(entryRepositoryProvider);
    if (_editing) {
      await repo.update(widget.entryId!, draft);
    } else {
      await repo.add(draft);
    }
    if (_category != null) await ref.read(categoryRepositoryProvider).touch(_category!.id);
    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _when?.toLocal() ?? now;
    final d = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(2000), lastDate: DateTime(now.year + 1, 12, 31));
    if (d == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, current.hour, current.minute).toUtc());
  }

  Future<void> _pickTime() async {
    final current = _when?.toLocal() ?? DateTime.now();
    final tm = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (tm == null) return;
    setState(() => _when = DateTime(current.year, current.month, current.day, tm.hour, tm.minute).toUtc());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;
    final expense = _kind == 'expense';
    final accent = expense ? c.expense : c.income;
    final accentTint = expense ? c.expenseTint : c.incomeTint;
    final amountError = _tried && ((_paise ?? 0) <= 0);
    final payError = _tried && _mode == null;
    final cat = _category;
    final catColor = cat == null ? c.textSecondary : Color(cat.color);
    final when = _when;
    final day = when == null ? null : Ist.dateOf(when);

    return AppPage(
      child: SafeArea(
        child: !_loaded
            ? const SizedBox.shrink()
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(children: [
                    HeaderButton(icon: LucideIcons.x, tooltip: l.close, onTap: () => context.pop()),
                    Expanded(
                      child: Center(
                        child: SegmentedSwitch(
                          options: [l.expense, l.income],
                          index: expense ? 0 : 1,
                          activeColors: [c.expenseButton, c.incomeButton],
                          onChanged: (i) => setState(() {
                            final k = i == 0 ? 'expense' : 'income';
                            if (k != _kind) _category = null;
                            _kind = k;
                          }),
                        ),
                      ),
                    ),
                    if (_editing)
                      IconButton(
                        tooltip: l.delete,
                        icon: Icon(LucideIcons.trash2, color: c.expense),
                        onPressed: () async {
                          final entry = HomeEntry(
                            id: widget.entryId!,
                            kind: expense ? EntryKind.expense : EntryKind.income,
                            amount: _paise ?? 0,
                            occurredAt: _when ?? DateTime.now(),
                            paymentMode: _mode ?? 'cash',
                            title: _title.text.isEmpty ? null : _title.text,
                          );
                          final deleted = await confirmAndDeleteEntry(context, ref, entry, cat);
                          if (deleted && context.mounted) context.pop();
                        },
                      )
                    else
                      const SizedBox(width: 48),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _padOpen = true),
                        child: Semantics(
                          label: l.amount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: amountError ? ShapeDecoration(shape: AppShapes.squircle(AppRadii.md, side: BorderSide(color: c.expense, width: 2))) : null,
                            child: AmountText(
                              '${expense ? Money.minus : '+'} ₹${Money.formatTyping(_amount)}',
                              size: 48,
                              color: accent,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                      if (amountError)
                        Center(child: Text(l.enterAmount, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600))),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Material(
                          color: c.card,
                          shape: AppShapes.squircle(AppRadii.pill),
                          child: InkWell(
                            customBorder: AppShapes.squircle(AppRadii.pill),
                            onTap: () async {
                              final picked = await pickCategory(context, kind: _kind, selectedId: _category?.id);
                              if (picked != null) setState(() => _category = picked);
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconTile(icon: categoryIcon(cat?.icon ?? 'others'), color: categoryInk(catColor, b), tint: categoryTint(catColor, b), size: 30),
                                const SizedBox(width: 8),
                                Text(cat == null ? l.category : categoryName(l, cat), style: t.titleSmall),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.chevronDown, size: 18, color: c.textMuted),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: Column(children: [
                          _FieldRow(
                            icon: LucideIcons.squarePen,
                            label: l.titleOptional,
                            child: TextField(
                              controller: _title,
                              onTap: () => setState(() => _padOpen = false),
                              decoration: InputDecoration.collapsed(hintText: l.addTitle),
                              style: t.titleSmall,
                            ),
                          ),
                          Divider(height: 1, color: c.border),
                          _FieldRow(
                            icon: LucideIcons.calendar,
                            label: l.date,
                            onTap: _pickDate,
                            child: _NowValue(text: day == null ? '${l.today}, ${shortDate(context, Ist.today())}' : (day == Ist.today() ? '${l.today}, ${shortDate(context, day)}' : longDate(context, day)), now: when == null, nowLabel: l.now),
                          ),
                          Divider(height: 1, color: c.border),
                          _FieldRow(
                            icon: LucideIcons.clock,
                            label: l.time,
                            onTap: _pickTime,
                            child: _NowValue(text: timeLabel(context, when ?? DateTime.now()), now: when == null, nowLabel: l.now),
                          ),
                        ]),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PaymentPicker(
                        label: expense ? l.paidVia : l.receivedIn,
                        mode: _mode,
                        method: _method,
                        accent: accent,
                        accentTint: accentTint,
                        errorText: payError ? (expense ? l.choosePayment : l.chooseReceived) : null,
                        onChanged: (m, method) => setState(() {
                          _mode = m;
                          _method = method;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: _FieldRow(
                          icon: LucideIcons.stickyNote,
                          label: l.note,
                          child: TextField(
                            controller: _note,
                            onTap: () => setState(() => _padOpen = false),
                            decoration: InputDecoration.collapsed(hintText: l.addNote),
                            style: t.titleSmall,
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_padOpen)
                  _AmountPad(
                    label: l.amount,
                    doneLabel: l.done,
                    doneKind: expense ? AppButtonKind.danger : AppButtonKind.success,
                    onDigit: (d) => setState(() => _amount = AmountTyping.press(_amount, d)),
                    onBackspace: () => setState(() => _amount = AmountTyping.backspace(_amount)),
                    onDone: () => setState(() => _padOpen = false),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
                    child: AppButton(label: expense ? l.saveExpense : l.saveIncome, kind: expense ? AppButtonKind.danger : AppButtonKind.success, onPressed: _save),
                  ),
              ]),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.label, required this.child, this.onTap});

  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(children: [
          IconTile(icon: icon, color: c.textSecondary, tint: c.raised, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              child,
            ]),
          ),
          if (onTap != null) Icon(LucideIcons.chevronRight, color: c.textMuted),
        ]),
      ),
    );
  }
}

class _NowValue extends StatelessWidget {
  const _NowValue({required this.text, required this.now, required this.nowLabel});

  final String text;
  final bool now;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
      if (now) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(AppRadii.pill)),
          child: Text(nowLabel, style: t.labelSmall?.copyWith(color: c.brandText, fontSize: 10)),
        ),
      ],
    ]);
  }
}

class _AmountPad extends StatelessWidget {
  const _AmountPad({required this.label, required this.doneLabel, required this.doneKind, required this.onDigit, required this.onBackspace, required this.onDone});

  final String label;
  final String doneLabel;
  final AppButtonKind doneKind;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final short = MediaQuery.sizeOf(context).height < 700;
    return Material(
      color: c.sheet,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Padding(padding: const EdgeInsets.only(left: 6), child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
            const Spacer(),
            AppButton(label: doneLabel, onPressed: onDone, expand: false, height: 40, kind: doneKind),
          ]),
          const SizedBox(height: 8),
          NumberPad(onDigit: onDigit, onBackspace: onBackspace, keyHeight: short ? 44 : 52),
        ]),
      ),
    );
  }
}
