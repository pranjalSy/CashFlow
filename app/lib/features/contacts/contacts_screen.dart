import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/calculations.dart';
import '../../data/repositories/people_repository.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/tab_page.dart';
import 'contacts_controller.dart';

/// Contacts tab (FR-D9, screen 13): to receive / to pay, recent 5, search, all phone contacts.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final people = ref.watch(peopleByIdProvider).value ?? const <String, PeopleData>{};
    final balances = ref.watch(personBalancesProvider).value ?? const <String, PersonBalance>{};
    final activity = ref.watch(lastActivityProvider).value ?? const <String, DateTime>{};
    final contacts = ref.watch(phoneContactsProvider);

    var toReceive = 0, toPay = 0, receiveCount = 0, payCount = 0;
    for (final b in balances.values) {
      if (b.net > 0) {
        toReceive += b.net;
        receiveCount++;
      } else if (b.net < 0) {
        toPay += -b.net;
        payCount++;
      }
    }

    final byPhone = {
      for (final p in people.values)
        if (p.phoneNormalized != null) p.phoneNormalized!: p,
    };
    final q = _query.trim().toLowerCase();
    final recent = (activity.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => people[e.key])
        .whereType<PeopleData>()
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .take(5)
        .toList();

    final phoneList = contacts.value;
    final shownContacts = phoneList == null
        ? const <Contact>[]
        : phoneList
              .where((x) => q.isEmpty || contactName(x)!.toLowerCase().contains(q) || x.phones.any((p) => p.number.replaceAll(' ', '').contains(q)))
              .toList();

    return TabPage(
      title: l.contactsTitle,
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalCard(label: l.toReceive, amount: toReceive, count: receiveCount, color: c.lent, tint: c.lentTint, icon: LucideIcons.arrowDownLeft),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _TotalCard(label: l.toPay, amount: toPay, count: payCount, color: c.borrowed, tint: c.borrowedTint, icon: LucideIcons.arrowUpRight),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: l.searchPeople,
            prefixIcon: const Icon(LucideIcons.search),
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
        if (recent.isNotEmpty) ...[
          SectionLabel(l.recentPeople),
          for (final p in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _PersonRow(name: p.name, subtitle: p.phoneNormalized, balance: balances[p.id], onTap: () => context.push('/person/${p.id}')),
            ),
        ],
        if (phoneList == null && !contacts.isLoading) // never flash "off" while reading
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _ContactsOffCard(
              onTurnOn: () async {
                await ref.read(contactsAccessProvider).request();
                ref.invalidate(phoneContactsProvider);
              },
              onAddPerson: () => _addPerson(context),
            ),
          )
        else ...[
          SectionLabel(
            l.allContacts,
            trailing: TextButton(onPressed: () => _addPerson(context), child: Text(l.addPerson)),
          ),
          if (shownContacts.isEmpty && recent.isEmpty)
            AppCard(
              child: EmptyState(icon: LucideIcons.users, title: l.noPeopleTitle, message: l.noPeopleBody),
            ),
          for (final (i, x) in shownContacts.indexed) ...[
            if (i == 0 || _letter(shownContacts[i - 1]) != _letter(x))
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 0, 4),
                child: Text(_letter(x), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.brandText)),
              ),
            FadeSlideIn(
              key: ValueKey(x.id),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Builder(
                  builder: (context) {
                    final phone = x.phones.isEmpty ? null : x.phones.first.number;
                    final saved = byPhone[PeopleRepository.normalizePhone(phone)];
                    final ref0 = PersonRef(id: saved?.id, name: contactName(x)!, phone: phone, contactId: x.id);
                    return _PersonRow(
                      name: ref0.name,
                      subtitle: phone,
                      balance: saved == null ? null : balances[saved.id],
                      onTap: () => saved != null
                          ? context.push('/person/${saved.id}')
                          : context.push(Uri(path: '/person/contact', queryParameters: ref0.toQuery()).toString()),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  static String _letter(Contact c) {
    final n = (c.displayName ?? '').trim();
    final first = n.isEmpty ? '' : n.characters.first.toUpperCase();
    return RegExp(r'\p{L}', unicode: true).hasMatch(first) ? first : '#';
  }

  Future<void> _addPerson(BuildContext context) async {
    final l = context.l10n;
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.addPerson, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.personName),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.personPhone),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: l.continueLabel, onPressed: () => Navigator.pop(context, name.text.trim().isNotEmpty)),
          ],
        );
      },
    );
    if (ok == true && context.mounted) {
      final r = PersonRef(name: name.text.trim(), phone: phone.text.trim().isEmpty ? null : phone.text.trim());
      context.push(Uri(path: '/person/contact', queryParameters: r.toQuery()).toString());
    }
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.amount, required this.count, required this.color, required this.tint, required this.icon});

  final String label;
  final int amount;
  final int count;
  final Color color;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(AppRadii.lg)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            AmountText(Money.format(amount), size: 22, color: color),
            Text(context.l10n.peopleCount(count), style: t.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.name, this.subtitle, this.balance, required this.onTap});

  final String name;
  final String? subtitle;
  final PersonBalance? balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final net = balance?.net ?? 0;
    final receive = net > 0;
    final color = net == 0 ? c.textSecondary : (receive ? c.lent : c.borrowed);
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          PersonAvatar(
            name: name,
            color: color == c.textSecondary ? c.brandText : color,
            tint: receive || net == 0 ? c.lentTint : c.borrowedTint,
            circle: true,
            size: 42,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (net != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(Money.format(net.abs()), color: color, alignment: Alignment.centerRight),
                Text(receive ? l.toReceiveLabel : l.toPayLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContactsOffCard extends StatelessWidget {
  const _ContactsOffCard({required this.onTurnOn, required this.onAddPerson});

  final VoidCallback onTurnOn;
  final VoidCallback onAddPerson;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: LucideIcons.userX, color: c.brandText, tint: c.brandTint, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.contactsOffTitle, style: t.titleMedium),
                const SizedBox(height: 4),
                Text(l.contactsOffBody, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(label: l.turnOn, onPressed: onTurnOn, expand: false, height: 44),
                    AppButton(label: l.addPerson, onPressed: onAddPerson, expand: false, height: 44, kind: AppButtonKind.secondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
