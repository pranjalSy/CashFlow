import 'package:flutter/material.dart';
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
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/payment_picker.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/premium_sheet.dart';
import 'contacts_controller.dart';

/// Add Lent / Borrowed (FR-D1, screen 15). Person, amount and payment are required (G1);
/// due date and reminders are Premium (G3) — Free users see the tag and the small paywall.
class UdharFormScreen extends ConsumerStatefulWidget {
  const UdharFormScreen({super.key, required this.direction, this.person});

  final String direction;
  final PersonRef? person;

  @override
  ConsumerState<UdharFormScreen> createState() => _UdharFormScreenState();
}

class _UdharFormScreenState extends ConsumerState<UdharFormScreen> {
  PersonRef? _person;
  String _amount = '';
  bool _padOpen = true;
  DateTime? _when;
  String? _mode;
  String? _method;
  final _note = TextEditingController();
  LocalDate? _due;
  final Set<int> _remind = {3};
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _lent => widget.direction == 'lent';

  Future<void> _save(bool premium) async {
    final amount = Money.parse(_amount) ?? 0;
    if (_person == null || amount <= 0 || _mode == null) {
      setState(() => _tried = true);
      return;
    }
    final people = ref.read(peopleRepositoryProvider);
    final p = _person!;
    final personId = p.id ?? (await people.findOrCreate(name: p.name, phone: p.phone, contactId: p.contactId)).id;
    await ref.read(debtRepositoryProvider).add(
          personId: personId,
          direction: widget.direction,
          amount: amount,
          occurredAt: (_when ?? DateTime.now()).toUtc(),
          paymentMode: _mode!,
          onlineMethod: _method,
          note: _note.text,
          dueDate: _due,
          reminderDays: _due == null ? const [] : _remind.toList(),
          premium: premium,
        );
    if (mounted) context.pop();
  }

  Future<void> _pickPerson() async {
    final picked = await showAppSheet<PersonRef>(context, builder: (_) => const _PersonPicker());
    if (picked != null) setState(() => _person = picked);
  }

  void _premiumOnly() {
    final l = context.l10n;
    showPremiumSheet(
      context,
      icon: Icons.calendar_today_rounded,
      title: l.premiumSheetDueTitle,
      body: l.premiumSheetDueBody(_person?.name.split(' ').first ?? l.person),
      footnote: l.premiumSavedWithout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final color = _lent ? c.lent : c.borrowed;
    final tint = _lent ? c.lentTint : c.borrowedTint;
    final amount = Money.parse(_amount) ?? 0;
    final when = _when;
    final day = when == null ? Ist.today() : Ist.dateOf(when);
    return AppPage(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close_rounded, color: c.text), tooltip: l.close),
              Expanded(child: Center(child: Text(_lent ? l.addLentTitle : l.addBorrowedTitle, style: t.titleLarge))),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              AppCard(
                radius: AppRadii.md,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onTap: _pickPerson,
                child: ListRowTile(
                  leading: _person == null
                      ? IconTile(icon: Icons.person_add_alt_rounded, color: color, tint: tint)
                      : PersonAvatar(name: _person!.name, color: color, tint: tint, circle: true),
                  title: _person?.name ?? l.choosePerson,
                  subtitle: _person == null ? l.person : _person!.phone,
                  trailing: Icon(Icons.expand_more_rounded, color: _tried && _person == null ? c.expense : c.textMuted),
                ),
              ),
              if (_tried && _person == null)
                Padding(padding: const EdgeInsets.only(left: 4, top: 6), child: Text(l.choosePerson, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600))),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => setState(() => _padOpen = true),
                child: AmountText('₹${Money.formatTyping(_amount)}', size: 44, color: color, alignment: Alignment.center),
              ),
              if (_tried && amount <= 0) Center(child: Text(l.enterAmount, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Column(children: [
                  ListRowTile(
                    leading: IconTile(icon: Icons.calendar_today_rounded, color: c.textSecondary, tint: c.raised, size: 34),
                    title: day == Ist.today() ? '${l.today}, ${shortDate(context, day)}' : longDate(context, day),
                    subtitle: l.date,
                    onTap: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(context: context, initialDate: (when ?? now).toLocal(), firstDate: DateTime(2000), lastDate: now);
                      if (d != null) setState(() => _when = DateTime(d.year, d.month, d.day, 12).toUtc());
                    },
                  ),
                  Divider(height: 1, color: c.border),
                  ListRowTile(
                    leading: IconTile(icon: Icons.event_available_rounded, color: c.textSecondary, tint: c.raised, size: 34),
                    title: _due == null ? l.noDueDate : longDate(context, _due!),
                    subtitle: l.dueDate,
                    trailing: premium ? null : const PremiumTag(),
                    onTap: premium
                        ? () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 7)), firstDate: now, lastDate: DateTime(now.year + 5));
                            if (d != null) setState(() => _due = LocalDate(d.year, d.month, d.day));
                          }
                        : _premiumOnly,
                  ),
                ]),
              ),
              if (premium && _due != null) ...[
                SectionLabel(l.remindMe),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final d in const [0, 3, 7])
                    AppChip(
                      label: d == 0 ? l.onDueDay : l.daysBefore(d),
                      selected: _remind.contains(d),
                      onTap: () => setState(() => _remind.contains(d) ? _remind.remove(d) : _remind.add(d)),
                    ),
                ]),
              ],
              const SizedBox(height: AppSpacing.md),
              PaymentPicker(
                label: _lent ? l.paidVia : l.receivedIn,
                mode: _mode,
                method: _method,
                accent: color,
                accentTint: tint,
                errorText: _tried && _mode == null ? (_lent ? l.choosePayment : l.chooseReceived) : null,
                onChanged: (m, method) => setState(() {
                  _mode = m;
                  _method = method;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: TextField(
                  controller: _note,
                  onTap: () => setState(() => _padOpen = false),
                  decoration: InputDecoration.collapsed(hintText: l.addNote),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
            ]),
          ),
          if (_padOpen)
            Material(
              color: c.sheet,
              elevation: 12,
              shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Padding(padding: const EdgeInsets.only(left: 6), child: Text(l.amount, style: t.labelMedium)),
                    const Spacer(),
                    AppButton(label: l.done, onPressed: () => setState(() => _padOpen = false), expand: false, height: 40),
                  ]),
                  const SizedBox(height: 8),
                  NumberPad(
                    keyHeight: MediaQuery.sizeOf(context).height < 700 ? 44 : 52,
                    onDigit: (d) => setState(() => _amount = AmountTyping.press(_amount, d)),
                    onBackspace: () => setState(() => _amount = AmountTyping.backspace(_amount)),
                  ),
                ]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: AppButton(label: _lent ? l.saveLent : l.saveBorrowed, onPressed: () => _save(premium)),
            ),
        ]),
      ),
    );
  }
}

/// Choose someone: saved people first, then phone contacts, or type a name.
class _PersonPicker extends ConsumerStatefulWidget {
  const _PersonPicker();

  @override
  ConsumerState<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends ConsumerState<_PersonPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final people = ref.watch(peopleByIdProvider).value?.values.toList() ?? const [];
    final contacts = ref.watch(phoneContactsProvider).value ?? const [];
    final q = _q.trim().toLowerCase();
    final savedPhones = {for (final p in people) ?p.phoneNormalized};
    final matchesPeople = people.where((p) => q.isEmpty || p.name.toLowerCase().contains(q)).toList();
    final matchesContacts = contacts
        .where((x) => !savedPhones.contains(PeopleRepository.normalizePhone(x.phones.isEmpty ? null : x.phones.first.number)))
        .where((x) => q.isEmpty || contactName(x)!.toLowerCase().contains(q))
        .take(60)
        .toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.choosePerson, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(hintText: l.searchPeople, prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: c.raised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        ),
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            if (q.isNotEmpty)
              ListRowTile(
                leading: IconTile(icon: Icons.person_add_alt_rounded, color: c.brandText, tint: c.brandTint),
                title: '${l.addPerson}: ${_q.trim()}',
                onTap: () => Navigator.pop(context, PersonRef(name: _q.trim())),
              ),
            for (final p in matchesPeople)
              ListRowTile(
                leading: PersonAvatar(name: p.name, color: c.lent, tint: c.lentTint, circle: true),
                title: p.name,
                subtitle: p.phoneNormalized,
                onTap: () => Navigator.pop(context, PersonRef(id: p.id, name: p.name, phone: p.phoneNormalized)),
              ),
            for (final x in matchesContacts)
              ListRowTile(
                leading: PersonAvatar(name: contactName(x)!, color: c.textSecondary, tint: c.raised, circle: true),
                title: contactName(x)!,
                subtitle: x.phones.isEmpty ? null : x.phones.first.number,
                onTap: () => Navigator.pop(context, PersonRef(name: contactName(x)!, phone: x.phones.isEmpty ? null : x.phones.first.number, contactId: x.id)),
              ),
          ]),
        ),
      ]),
    );
  }
}
