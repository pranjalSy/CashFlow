import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../features/entry/entry_form_screen.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/app_page.dart';
import '../shared/widgets/states.dart';
import '../shared/widgets/tab_page.dart';

/// Pushed screens on top of the tabs.
final List<RouteBase> extraRoutes = [
  GoRoute(path: '/entry/new', builder: (_, s) => EntryFormScreen(kind: s.uri.queryParameters['kind'] == 'income' ? 'income' : 'expense')),
  GoRoute(path: '/entry/:id', builder: (_, s) => EntryFormScreen(entryId: s.pathParameters['id'])),
  GoRoute(path: '/settings', builder: (_, _) => const _ComingSoonPage()),
];

/// Settings arrive in T14; the avatar already opens this page.
class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppPage(
      child: Stack(children: [
        TabPage(children: [
          const SizedBox(height: 48),
          AppCard(child: EmptyState(icon: Icons.settings_rounded, title: l.comingSoon, message: l.welcomeOfflineNote)),
        ]),
        SafeArea(child: BackButton(onPressed: () => context.pop())),
      ]),
    );
  }
}
