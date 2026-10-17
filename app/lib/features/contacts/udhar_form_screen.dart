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
import '../../data/repositories/profile_repository.dart';
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
  late String _direction = widget.direction;
  String _amount = '';
  bool _padOpen = true;
  DateTime? _when;
  String? _mode;
  String? _method;
  final _note = TextEditingController();
  LocalDate? _due;
  /// Remind me: null = Off, else 3 or 7 days before; the due day is always reminded (FR-D5, screen 15).
  /// Starts from Settings › Default reminder (FR-R2).
  int? _remindBefore = 3;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    ref.read(profileRepositoryProvider).current().then((p) {
      final days = p?.defaultReminderDays ?? 3;
      if (mounted) setState(() => _remindBefore = days == 0 ? null : days);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _lent => _direction == 'lent';

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
          direction: _direction,
          amount: amount,
          occurredAt: (_when ?? DateTime.now()).toUtc(),
          paymentMode: _mode!,
          onlineMethod: _method,
          note: _note.text,
          dueDate: _due,
          reminderDays: _due == null ? const [] : [0, ?_remindBefore],
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
      icon: LucideIcons.calendar,
      title: l.premiumSheetDueTitle,
      body: l.premiumSheetDueBody(_person?.name.split(' ').first ?? l.person),
      footnote: l.premiumSavedWithout,
    );
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 7)), firstDate: now, lastDate: DateTime(now.year + 5));
    if (d != null) setState(() => _due = LocalDate(d.year, d.month, d.day));
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
    final first = _person?.name.split(' ').first;
    final today = Ist.today();
    final presets = [(l.oneWeek, today.addDays(7)), (l.twoWeeks, today.addDays(14)), (l.oneMonth, today.addMonths(1))];

    Widget small(String text, {bool premiumTag = false}) => Padding(
          padding: const EdgeInsets.only(left: 4, top: AppSpacing.sm, bottom: 6),
          child: Row(children: [
            Text(text, style: t.labelMedium?.copyWith(color: c.text)),
            if (premiumTag) ...[const SizedBox(width: 6), const PremiumTag()],
          ]),
        );

    return AppPage(
      lightGlow: tint,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 0),
            child: Row(children: [
              HeaderButton(icon: LucideIcons.x, tooltip: l.close, onTap: () => context.pop()),
              Expanded(
                child: Center(
                  // Lent (blue) | Borrowed (pink): the whole screen changes colour (screen 15).
                  child: SegmentedSwitch(
                    options: [l.lent, l.borrowed],
                    index: _lent ? 0 : 1,
                    activeColors: [c.lent, c.borrowed],
                    onChanged: (i) => setState(() => _direction = i == 0 ? 'lent' : 'borrowed'),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md), children: [
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                border: _tried && _person == null ? BorderSide(color: c.expense, width: 2) : null,
                onTap: _pickPerson,
                child: Row(children: [
                  _person == null
                      ? IconTile(icon: LucideIcons.userPlus, color: color, tint: tint)
                      : PersonAvatar(name: _person!.name, color: color, tint: tint, circle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_person?.name ?? l.choosePerson, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_person == null ? l.fromContactsOrNew : (_person!.phone ?? ''), style: t.bodySmall),
                    ]),
                  ),
                  if (_person != null)
                    Text(l.change, style: t.labelLarge?.copyWith(color: color))
                  else
                    Icon(LucideIcons.chevronRight, color: c.textMuted),
                ]),
              ),
              if (_tried && _person == null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(_lent ? l.chooseWhoLent : l.chooseWhoBorrowed, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => setState(() => _padOpen = true),
                child: AmountText('₹${Money.formatTyping(_amount)}', size: 46, color: color, alignment: Alignment.center),
              ),
              Center(
                child: Text(
                  _lent ? (first == null ? l.youGaveSomeone : l.youGave(first)) : (first == null ? l.youTookSomeone : l.youTook(first)),
                  style: t.bodySmall,
                ),
              ),
              if (_tried && amount <= 0) Center(child: Text(l.enterAmount, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600))),
              const SizedBox(height: AppSpacing.xs),
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
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  _FormRow(
                    icon: LucideIcons.calendar,
                    label: l.date,
                    value: day == today ? '${l.today}, ${shortDate(context, day)}' : longDate(context, day),
                    badge: when == null ? l.now : null,
                    onTap: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(context: context, initialDate: (when ?? now).toLocal(), firstDate: DateTime(2000), lastDate: now);
                      if (d != null) setState(() => _when = DateTime(d.year, d.month, d.day, 12).toUtc());
                    },
                  ),
                  Divider(height: 1, color: c.border),
                  _FormRow(
                    icon: LucideIcons.calendarCheck,
                    label: l.dueDate,
                    premiumTag: true,
                    value: _due == null ? l.noDueDate : longDate(context, _due!),
                    onTap: premium ? _pickDue : _premiumOnly,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (label, date) in presets)
                  AppChip(label: label, selected: _due == date, onTap: premium ? () => setState(() => _due = date) : _premiumOnly),
                AppChip(label: l.pickDate, selected: false, onTap: premium ? _pickDue : _premiumOnly),
              ]),
              small(l.remindMe, premiumTag: true),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final d in const [null, 3, 7])
                  AppChip(
                    label: d == null ? l.remindOff : l.daysBefore(d),
                    selected: _remindBefore == d,
                    onTap: premium ? () => setState(() => _remindBefore = d) : _premiumOnly,
                  ),
              ]),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  IconTile(icon: LucideIcons.stickyNote, color: c.textSecondary, tint: c.raised, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.note, style: t.labelSmall),
                      TextField(
                        controller: _note,
                        onTap: () => setState(() => _padOpen = false),
                        decoration: InputDecoration.collapsed(hintText: l.addNote),
                        style: t.titleSmall,
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ]),
                  ),
                ]),
              ),
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
                    Padding(padding: const EdgeInsets.only(left: 6), child: Text(l.amount, style: t.labelMedium)),
                    const Spacer(),
                    AppButton(label: l.done, color: color, onPressed: () => setState(() => _padOpen = false), expand: false, height: 40),
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
              child: AppButton(label: _lent ? l.saveLent : l.saveBorrowed, color: color, onPressed: () => _save(premium)),
            ),
        ]),
      ),
    );
  }
}

/// Date / Due date row: small label above, value below, optional "Now" badge or Premium tag (screen 15).
class _FormRow extends StatelessWidget {
  const _FormRow({required this.icon, required this.label, required this.value, required this.onTap, this.badge, this.premiumTag = false});

  final IconData icon;
  final String label;
  final String value;
  final String? badge;
  final bool premiumTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          IconTile(icon: icon, color: c.textSecondary, tint: c.raised, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: t.labelSmall),
                if (premiumTag) ...[const SizedBox(width: 6), const PremiumTag()],
              ]),
              Row(children: [
                Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(AppRadii.pill)),
                    child: Text(badge!, style: t.labelSmall?.copyWith(color: c.brandText)),
                  ),
                ],
              ]),
            ]),
          ),
          Icon(LucideIcons.chevronRight, color: c.textMuted, size: 18),
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
          decoration: InputDecoration(hintText: l.searchPeople, prefixIcon: const Icon(LucideIcons.search), filled: true, fillColor: c.raised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        ),
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            if (q.isNotEmpty)
              ListRowTile(
                leading: IconTile(icon: LucideIcons.userPlus, color: c.brandText, tint: c.brandTint),
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
