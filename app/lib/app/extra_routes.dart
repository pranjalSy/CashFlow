import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/flavor.dart';
import '../core/l10n.dart';
import '../data/repositories/plan_repository.dart';
import '../features/contacts/contacts_controller.dart';
import '../features/contacts/person_detail_screen.dart';
import '../features/contacts/udhar_form_screen.dart';
import '../features/bills/bill_detail_screen.dart';
import '../features/bills/bill_form_screen.dart';
import '../features/bills/bill_type_screen.dart';
import '../features/charts/budget_screen.dart';
import '../features/emi/emi_detail_screen.dart';
import '../features/emi/emi_form_screen.dart';
import '../features/entry/entry_form_screen.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/app_page.dart';
import '../shared/widgets/basics.dart';
import '../shared/widgets/states.dart';
import '../shared/widgets/tab_page.dart';

/// Pushed screens on top of the tabs.
final List<RouteBase> extraRoutes = [
  GoRoute(path: '/entry/new', builder: (_, s) => EntryFormScreen(kind: s.uri.queryParameters['kind'] == 'income' ? 'income' : 'expense')),
  GoRoute(path: '/entry/:id', builder: (_, s) => EntryFormScreen(entryId: s.pathParameters['id'])),
  GoRoute(path: '/person/contact', builder: (_, s) => PersonDetailScreen(person: _refFrom(s.uri.queryParameters))),
  GoRoute(
    path: '/person/:id',
    builder: (_, s) => PersonDetailScreen(person: PersonRef(id: s.pathParameters['id'], name: s.uri.queryParameters['name'] ?? '')),
  ),
  GoRoute(
    path: '/udhar/new',
    builder: (_, s) {
      final q = s.uri.queryParameters;
      final hasPerson = q['person'] != null || q['name'] != null;
      return UdharFormScreen(direction: q['direction'] == 'borrowed' ? 'borrowed' : 'lent', person: hasPerson ? _refFrom(q, id: q['person']) : null);
    },
  ),
  GoRoute(path: '/emi/new', builder: (_, _) => const EmiFormScreen()),
  GoRoute(path: '/emi/:id', builder: (_, s) => EmiDetailScreen(emiId: s.pathParameters['id']!)),
  GoRoute(path: '/emi/:id/edit', builder: (_, s) => EmiFormScreen(emiId: s.pathParameters['id'])),
  GoRoute(path: '/bills/new', builder: (_, _) => const BillTypeScreen()),
  GoRoute(
    path: '/bills/new/form',
    builder: (_, s) {
      final q = s.uri.queryParameters;
      return BillFormScreen(type: q['type'] ?? 'other', name: q['name'], gap: int.tryParse(q['gap'] ?? ''));
    },
  ),
  GoRoute(path: '/bills/:id', builder: (_, s) => BillDetailScreen(billId: s.pathParameters['id']!)),
  GoRoute(path: '/bills/:id/edit', builder: (_, s) => BillFormScreen(billId: s.pathParameters['id'])),
  GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
  GoRoute(path: '/settings', builder: (_, _) => const _ComingSoonPage()),
];

PersonRef _refFrom(Map<String, String> q, {String? id}) => PersonRef(id: id, name: q['name'] ?? '', phone: q['phone'], contactId: q['cid']);

/// Settings arrive in T14; the avatar already opens this page.
/// In the dev flavor it also has the Premium switch used to test Premium screens before billing (T20).
class _ComingSoonPage extends ConsumerWidget {
  const _ComingSoonPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    return AppPage(
      child: Stack(children: [
        TabPage(children: [
          const SizedBox(height: 48),
          AppCard(child: EmptyState(icon: LucideIcons.settings, title: l.comingSoon, message: l.welcomeOfflineNote)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListRowTile(leading: const Icon(LucideIcons.target), title: l.budget, onTap: () => context.push('/budget')),
          ),
          if (FlavorConfig.instance.isDev) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListRowTile(
                leading: const Icon(LucideIcons.award),
                title: l.devPremiumToggle,
                onTap: () => ref.read(planRepositoryProvider).setPremiumForDev(!premium),
                trailing: AppToggle(value: premium, onChanged: (v) => ref.read(planRepositoryProvider).setPremiumForDev(v)),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListRowTile(leading: const Icon(LucideIcons.layoutGrid), title: l.devGallery, onTap: () => context.push('/dev/gallery')),
            ),
          ],
        ]),
        SafeArea(child: BackButton(onPressed: () => context.pop())),
      ]),
    );
  }
}
