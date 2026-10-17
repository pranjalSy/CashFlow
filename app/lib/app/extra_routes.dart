import 'package:go_router/go_router.dart';

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
import '../features/export/export_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/change_pin_screen.dart';
import '../features/settings/settings_screen.dart';

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
  GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
  GoRoute(path: '/export', builder: (_, _) => const ExportScreen()),
  GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
  GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
  GoRoute(path: '/settings/pin', builder: (_, _) => const ChangePinScreen()),
];

PersonRef _refFrom(Map<String, String> q, {String? id}) => PersonRef(id: id, name: q['name'] ?? '', phone: q['phone'], contactId: q['cid']);
