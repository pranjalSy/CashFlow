import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/emi.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/emi_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import 'emi_lock.dart';

enum _Field { price, down, loan, rate, months, emi }

/// Add or edit an EMI (FR-E1–E3, FR-E9, screen 18). "I know the: Months | EMI amount";
/// the other one is worked out live. Save is never disabled: a "Not possible" EMI shakes the card.
class EmiFormScreen extends ConsumerStatefulWidget {
  const EmiFormScreen({super.key, this.emiId});

  final String? emiId;

  @override
  ConsumerState<EmiFormScreen> createState() => _EmiFormScreenState();
}

class _EmiFormScreenState extends ConsumerState<EmiFormScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _lender = TextEditingController();
  String _icon = 'bike';
  String _price = '';
  String _down = '';
  String _loan = '';
  bool _loanTyped = false;
  String _rate = '';
  String _months = '';
  String _emi = '';
  bool _knowMonths = true;
  LocalDate _first = Ist.today();
  _Field? _active;
  bool _tried = false;
  bool _termsLocked = false;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  bool get _editing => widget.emiId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _lender.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(emiRepositoryProvider);
    final e = await repo.byId(widget.emiId!);
    if (e == null || !mounted) return;
    final paid = await repo.paidCount(e.id);
    setState(() {
      _name.text = e.name;
      _lender.text = e.lender ?? '';
      _icon = e.icon;
      _price = e.itemPrice == null ? '' : AmountTyping.fromPaise(e.itemPrice!);
      _down = e.downPayment == null ? '' : AmountTyping.fromPaise(e.downPayment!);
      _loan = AmountTyping.fromPaise(e.loanAmount);
      _loanTyped = e.itemPrice == null;
      _rate = rateText(e.rateBp);
      _months = '${e.months}';
      _emi = AmountTyping.fromPaise(e.emiAmount);
      _first = LocalDate.parse(e.firstDueDate);
      _termsLocked = paid > 0;
    });
  }

  int get _loanPaise {
    if (_loanTyped || _price.isEmpty) return Money.parse(_loan) ?? 0;
    return math.max(0, (Money.parse(_price) ?? 0) - (Money.parse(_down) ?? 0));
  }

  int get _rateBp => Money.parse(_rate) ?? 0; // "12.5" → 1250, same shape as paise

  /// The plan from what is typed: (months, emi) or null when incomplete; impossible = true when the EMI is too small.
  ({int months, int emi, bool impossible})? get _plan {
    final loan = _loanPaise;
    if (loan <= 0) return null;
    if (_knowMonths) {
      final n = int.tryParse(_months) ?? 0;
      if (n <= 0) return null;
      return (months: n, emi: Emi.amount(principal: loan, rateBp: _rateBp, months: n), impossible: false);
    }
    final emi = Money.parse(_emi) ?? 0;
    if (emi <= 0) return null;
    final n = Emi.monthsFor(principal: loan, rateBp: _rateBp, emi: emi);
    return (months: n ?? 0, emi: emi, impossible: n == null);
  }

  void _press(String key) => setState(() {
        switch (_active) {
          case _Field.price:
            _price = AmountTyping.press(_price, key);
          case _Field.down:
            _down = AmountTyping.press(_down, key);
          case _Field.loan:
            if (!_loanTyped) _loan = AmountTyping.fromPaise(_loanPaise);
            _loanTyped = true;
            _loan = AmountTyping.press(_loan, key);
          case _Field.rate:
            final next = AmountTyping.press(_rate, key);
            if ((Money.parse(next) ?? 0) <= 9999) _rate = next;
          case _Field.months:
            final next = key == '.' ? _months : '$_months$key';
            if ((int.tryParse(next) ?? 0) <= Emi.maxMonths) _months = next.replaceFirst(RegExp(r'^0+'), '');
          case _Field.emi:
            _emi = AmountTyping.press(_emi, key);
          case null:
            break;
        }
      });

  void _backspace() => setState(() {
        switch (_active) {
          case _Field.price:
            _price = AmountTyping.backspace(_price);
          case _Field.down:
            _down = AmountTyping.backspace(_down);
          case _Field.loan:
            _loanTyped = true;
            _loan = AmountTyping.backspace(_loan);
          case _Field.rate:
            _rate = AmountTyping.backspace(_rate);
          case _Field.months:
            _months = AmountTyping.backspace(_months);
          case _Field.emi:
            _emi = AmountTyping.backspace(_emi);
          case null:
            break;
        }
      });

  void _open(_Field f) {
    if (_termsLocked) {
      CompactSnackbar.show(context, message: context.l10n.emiTermsLocked);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _active = f);
  }

  Future<void> _save() async {
    final plan = _plan;
    if (_name.text.trim().isEmpty || plan == null) {
      setState(() {
        _tried = true;
        _active = null;
      });
      return;
    }
    if (plan.impossible) {
      setState(() => _active = null);
      _shake.forward(from: 0);
      return;
    }
    final draft = EmiDraft(
      name: _name.text,
      icon: _icon,
      lender: _lender.text,
      itemPrice: _loanTyped ? null : Money.parse(_price),
      downPayment: _loanTyped ? null : Money.parse(_down),
      loanAmount: _loanPaise,
      rateBp: _rateBp,
      months: plan.months,
      emiAmount: plan.emi,
      firstDue: _first,
    );
    final repo = ref.read(emiRepositoryProvider);
    if (_editing) {
      await repo.update(widget.emiId!, draft);
    } else {
      await repo.add(draft);
    }
    if (mounted) context.pop();
  }

  Future<void> _pickIcon() async {
    final picked = await showAppSheet<String>(context, builder: (context) {
      final c = context.colors;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.l10n.chooseIcon, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (final k in emiIconKeys)
            InkResponse(
              onTap: () => Navigator.pop(context, k),
              child: IconTile(icon: emiIcon(k), color: k == _icon ? c.onButton : c.brandText, tint: k == _icon ? c.brandButton : c.brandTint, size: 52),
            ),
        ]),
      ]);
    });
    if (picked != null) setState(() => _icon = picked);
  }

  Future<void> _pickDate() async {
    if (_termsLocked) {
      CompactSnackbar.show(context, message: context.l10n.emiTermsLocked);
      return;
    }
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(_first.year, _first.month, _first.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (d != null) setState(() => _first = LocalDate(d.year, d.month, d.day));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final plan = _plan;
    final loanMissing = _tried && _loanPaise <= 0;
    final termMissing = _tried && _loanPaise > 0 && plan == null;

    return AppPage(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close_rounded, color: c.text), tooltip: l.close),
              Expanded(child: Center(child: Text(_editing ? l.editEmi : l.addEmi, style: t.titleLarge))),
              const SizedBox(width: 48),
            ]),
          ),
          if (!premium)
            const Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(AppSpacing.md), child: EmiLockCard()))
          else ...[
            Expanded(
              child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
                AppCard(
                  radius: AppRadii.md,
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  border: _tried && _name.text.trim().isEmpty ? BorderSide(color: c.expense, width: 2) : null,
                  child: Column(children: [
                    Row(children: [
                      InkResponse(onTap: _pickIcon, child: IconTile(icon: emiIcon(_icon), color: c.brandText, tint: c.brandTint)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.emiName, style: t.labelMedium),
                          TextField(
                            controller: _name,
                            onTap: () => setState(() => _active = null),
                            onChanged: (_) => setState(() {}),
                            style: t.titleMedium,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration.collapsed(hintText: l.emiNameHint),
                          ),
                        ]),
                      ),
                    ]),
                    Divider(height: 18, color: c.border),
                    TextField(
                      controller: _lender,
                      onTap: () => setState(() => _active = null),
                      style: t.bodyMedium,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration.collapsed(hintText: l.lenderOptional),
                    ),
                  ]),
                ),
                if (_tried && _name.text.trim().isEmpty) _error(context, l.emiNameMissing),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Expanded(child: AmountField(label: l.itemPrice, typed: _price, active: _active == _Field.price, onTap: () => _open(_Field.price))),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: AmountField(label: l.downPayment, typed: _down, active: _active == _Field.down, onTap: () => _open(_Field.down))),
                ]),
                const SizedBox(height: AppSpacing.xs),
                AmountField(
                  label: l.loanAmount,
                  typed: _loanTyped || _price.isEmpty ? _loan : AmountTyping.fromPaise(_loanPaise),
                  active: _active == _Field.loan,
                  error: loanMissing,
                  onTap: () => _open(_Field.loan),
                ),
                if (loanMissing) _error(context, l.loanMissing),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Expanded(child: _ValueField(label: l.interestYearly, value: _rate.isEmpty ? '0' : _rate, suffix: '%', active: _active == _Field.rate, onTap: () => _open(_Field.rate))),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _ValueField(label: l.firstEmiDate, value: longDate(context, _first), active: false, onTap: _pickDate)),
                ]),
                if (_termsLocked) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.emiTermsLocked, style: t.bodySmall?.copyWith(color: c.dueSoon, fontWeight: FontWeight.w600)),
                ],
                SectionLabel(l.iKnowThe),
                SegmentedSwitch(
                  options: [l.months, l.emiAmount],
                  index: _knowMonths ? 0 : 1,
                  onChanged: (i) {
                    if (_termsLocked) return _open(_Field.months);
                    setState(() {
                      _knowMonths = i == 0;
                      _active = _knowMonths ? _Field.months : _Field.emi;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_knowMonths)
                  _ValueField(
                    label: l.numberOfMonths,
                    value: _months.isEmpty ? '0' : _months,
                    suffix: l.months.toLowerCase(),
                    active: _active == _Field.months,
                    error: termMissing,
                    onTap: () => _open(_Field.months),
                  )
                else
                  AmountField(label: l.emiAmount, typed: _emi, active: _active == _Field.emi, error: termMissing, onTap: () => _open(_Field.emi)),
                if (termMissing) _error(context, l.emiTermMissing),
                const SizedBox(height: AppSpacing.sm),
                if (plan != null)
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) => Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value), 0), child: child),
                    child: plan.impossible ? _notPossible(context) : _result(context, plan.months, plan.emi),
                  ),
              ]),
            ),
            if (_active != null)
              Material(
                color: c.sheet,
                elevation: 12,
                shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Padding(padding: const EdgeInsets.only(left: 6), child: Text(_fieldLabel(l, _active!), style: t.labelMedium)),
                      const Spacer(),
                      AppButton(label: l.done, onPressed: () => setState(() => _active = null), expand: false, height: 40),
                    ]),
                    const SizedBox(height: 8),
                    NumberPad(keyHeight: MediaQuery.sizeOf(context).height < 700 ? 42 : 50, onDigit: _press, onBackspace: _backspace),
                  ]),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
                child: AppButton(label: l.saveEmi, onPressed: _save),
              ),
          ],
        ]),
      ),
    );
  }

  String _fieldLabel(AppLocalizations l, _Field f) => switch (f) {
        _Field.price => l.itemPrice,
        _Field.down => l.downPayment,
        _Field.loan => l.loanAmount,
        _Field.rate => l.interestYearly,
        _Field.months => l.numberOfMonths,
        _Field.emi => l.emiAmount,
      };

  Widget _error(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.expense, fontWeight: FontWeight.w600)),
      );

  Widget _result(BuildContext context, int months, int emi) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final s = Emi.schedule(principal: _loanPaise, rateBp: _rateBp, emi: emi, months: months, firstDue: _first);
    final total = s.fold(0, (a, i) => a + i.amount);
    final interest = total - _loanPaise;
    final last = s.last;
    final big = _knowMonths
        ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: AmountText(Money.format(emi), size: 30, color: c.brandText)),
            Padding(padding: const EdgeInsets.only(bottom: 5, left: 4), child: Text(l.perMonth, style: t.bodyMedium)),
          ])
        : Text(l.monthsCount(s.length), style: t.headlineSmall?.copyWith(color: c.brandText));
    return AppCard(
      radius: AppRadii.lg,
      color: c.brandTint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_knowMonths ? l.yourEmi : l.itWillTake, style: t.labelMedium),
        big,
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          if (_knowMonths) ...[
            Expanded(child: _Fact(label: l.totalInterest, value: Money.format(interest))),
            Expanded(child: _Fact(label: l.totalToPay, value: Money.format(total))),
            Expanded(child: _Fact(label: l.lastEmi, value: longDate(context, last.dueDate), money: false)),
          ] else ...[
            Expanded(child: _Fact(label: l.lastEmi, value: Money.format(last.amount))),
            Expanded(child: _Fact(label: l.totalInterest, value: Money.format(interest))),
            Expanded(child: _Fact(label: l.endsOn, value: longDate(context, last.dueDate), money: false)),
          ],
        ]),
        const SizedBox(height: 6),
        Text(l.totalsMayDiffer, style: t.bodySmall),
      ]),
    );
  }

  Widget _notPossible(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final interest = Money.format(Emi.firstMonthInterest(principal: _loanPaise, rateBp: _rateBp));
    return AppCard(
      radius: AppRadii.lg,
      color: c.expenseTint,
      border: BorderSide(color: c.expense, width: 1.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.error_outline_rounded, color: c.expense, size: 20),
          const SizedBox(width: 6),
          Text(l.notPossible, style: t.titleMedium?.copyWith(color: c.expense)),
        ]),
        const SizedBox(height: 4),
        Text(l.notPossibleTitle, style: t.titleSmall),
        const SizedBox(height: 2),
        Text(l.notPossibleBody(interest), style: t.bodySmall?.copyWith(color: c.textSecondary)),
      ]),
    );
  }
}

/// A tappable field showing a plain value (rate, months, date) in the same style as [AmountField].
class _ValueField extends StatelessWidget {
  const _ValueField({required this.label, required this.value, required this.active, required this.onTap, this.suffix, this.error = false});

  final String label;
  final String value;
  final String? suffix;
  final bool active;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final border = error ? c.expense : (active ? c.brandButton : c.border);
    final shape = AppShapes.squircle(AppRadii.md, side: BorderSide(color: border, width: active || error ? 2 : 1));
    return Material(
      color: c.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.labelMedium),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleLarge?.copyWith(fontSize: 20))),
              if (suffix != null) ...[const SizedBox(width: 4), Text(suffix!, style: t.bodyMedium)],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.money = true});

  final String label;
  final String value;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
      money ? AmountText(value, size: 14) : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
    ]);
  }
}
