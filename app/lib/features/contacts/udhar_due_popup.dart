import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/payment_picker.dart';
import '../../shared/widgets/person_avatar.dart';

/// On app open, asks about each udhar that is due (FR-D11, G9, screen 14b). Premium only.
/// Several due udhar are asked one after another.
Future<void> askDueUdhar(BuildContext context, WidgetRef ref) async {
  if (!await ref.read(planRepositoryProvider).isPremium()) return;
  final due = await ref.read(debtRepositoryProvider).dueToAsk(Ist.today());
  if (due.isEmpty) return;
  final people = ref.read(peopleRepositoryProvider);
  for (final d in due) {
    final name = (await people.byId(d.debt.personId))?.name ?? '';
    if (!context.mounted) return;
    await showAppPopup<void>(context, builder: (_) => UdharDuePopup(item: d, personName: name));
  }
}

enum _Stage { ask, full, some }

class UdharDuePopup extends ConsumerStatefulWidget {
  const UdharDuePopup({super.key, required this.item, required this.personName});

  final DebtWithPayments item;
  final String personName;

  @override
  ConsumerState<UdharDuePopup> createState() => _UdharDuePopupState();
}

class _UdharDuePopupState extends ConsumerState<UdharDuePopup> {
  _Stage _stage = _Stage.ask;
  String _amount = '';
  String? _mode;
  String? _method;
  bool _tried = false;
  bool _busy = false;

  DebtWithPayments get _item => widget.item;
  int get _paise => _stage == _Stage.full ? _item.remaining : (Money.parse(_amount) ?? 0);

  Future<void> _save() async {
    if (_busy) return;
    if (_paise <= 0 || _mode == null) {
      setState(() => _tried = true);
      return;
    }
    _busy = true;
    final l = context.l10n;
    final repo = ref.read(debtRepositoryProvider);
    final premium = ref.read(isPremiumProvider).value ?? false;
    final r = await repo.recordRepayment(debtId: _item.debt.id, amount: _paise, occurredAt: DateTime.now(), paymentMode: _mode!, onlineMethod: _method);
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (r.extra > 0) {
      final extra = Money.format(r.extra);
      CompactSnackbar.show(
        context,
        message: _item.lent ? l.extraAsBorrowed(extra) : l.extraAsLent(extra),
        actionLabel: l.yes,
        onAction: () => repo.addExtraAsDebt(_item.debt.id, premium: premium),
      );
    }
    nav.pop();
  }

  Future<void> _notYet() async {
    await ref.read(debtRepositoryProvider).askAgainTomorrow(_item.debt.id, Ist.today());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _changeDueDate({bool close = true}) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(context: context, initialDate: tomorrow, firstDate: tomorrow, lastDate: DateTime(now.year + 5));
    if (picked == null || !mounted) return;
    await ref.read(debtRepositoryProvider).extendDueDate(_item.debt.id, LocalDate(picked.year, picked.month, picked.day));
    if (close && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final lent = _item.lent;
    final d = _item.debt;
    final remaining = Money.format(_item.remaining);
    final given = shortDate(context, Ist.dateOf(d.occurredAt));
    final history = [
      lent ? l.lentOnDate(Money.format(d.amount), given) : l.borrowedOnDate(Money.format(d.amount), given),
      if (_item.repaid > 0) l.alreadyBack(Money.format(_item.repaid)),
    ].join(' · ');

    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: PersonAvatar(name: widget.personName, color: lent ? c.lent : c.borrowed, tint: lent ? c.lentTint : c.borrowedTint, size: 56, circle: true),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l.udharDueToday, textAlign: TextAlign.center, style: t.labelMedium?.copyWith(color: c.dueSoon, fontWeight: FontWeight.w700)),
        Text('${widget.personName} · $remaining', textAlign: TextAlign.center, style: t.titleLarge),
        Text(history, textAlign: TextAlign.center, style: t.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        ...switch (_stage) {
          _Stage.ask => _ask(context, remaining),
          _Stage.full || _Stage.some => _pay(context),
        },
      ]),
    );
  }

  List<Widget> _ask(BuildContext context, String remaining) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final lent = _item.lent;
    return [
      Text(lent ? l.didYouGetIt : l.didYouPayBack, textAlign: TextAlign.center, style: t.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: lent ? l.gotFull(remaining) : l.paidFull(remaining),
        kind: AppButtonKind.success,
        onPressed: () => setState(() => _stage = _Stage.full),
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(children: [
        Expanded(
          child: AppButton(label: lent ? l.gotSome : l.paidSome, kind: AppButtonKind.secondary, onPressed: () => setState(() => _stage = _Stage.some)),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: AppButton(label: l.notYet, kind: AppButtonKind.secondary, onPressed: _notYet)),
      ]),
      TextButton(onPressed: _changeDueDate, child: Text(l.changeDueDate)),
    ];
  }

  List<Widget> _pay(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final lent = _item.lent;
    final accent = lent ? c.income : c.expense;
    final some = _stage == _Stage.some;
    final left = _item.remaining - _paise;
    final due = widget.item.debt.dueDate;
    return [
      if (some) ...[
        Text(lent ? l.howMuchGot : l.howMuchPaid, textAlign: TextAlign.center, style: t.titleMedium),
        AmountText('₹${Money.formatTyping(_amount)}', size: 34, color: accent, alignment: Alignment.center),
        if (_tried && _paise <= 0)
          Text(l.enterAmount, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
        if (left > 0) ...[
          Text(l.stillLeft(Money.format(left)), textAlign: TextAlign.center, style: t.bodySmall),
          if (due != null)
            Center(
              child: TextButton(
                onPressed: () => _changeDueDate(close: false),
                child: Text(l.dueKeepOrChange(shortDate(context, LocalDate.parse(due)))),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.xs),
      ],
      PaymentPicker(
        label: lent ? l.receivedIn : l.paidVia,
        mode: _mode,
        method: _method,
        accent: accent,
        accentTint: lent ? c.incomeTint : c.expenseTint,
        errorText: _tried && _mode == null ? (lent ? l.chooseReceived : l.choosePayment) : null,
        onChanged: (m, method) => setState(() {
          _mode = m;
          _method = method;
        }),
      ),
      if (some) ...[
        const SizedBox(height: AppSpacing.xs),
        NumberPad(
          keyHeight: 42,
          onDigit: (d) => setState(() => _amount = AmountTyping.press(_amount, d)),
          onBackspace: () => setState(() => _amount = AmountTyping.backspace(_amount)),
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      AppButton(label: l.saveAmount(Money.format(_paise)), kind: AppButtonKind.success, onPressed: _save),
    ];
  }
}
