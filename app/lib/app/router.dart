import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/charts/charts_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/dev/gallery_screen.dart';
import '../features/emi/emi_bills_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lock/lock_controller.dart';
import '../features/lock/lock_screen.dart';
import '../features/onboarding/contacts_permission_screen.dart';
import '../features/onboarding/fingerprint_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/opening_balance_screen.dart';
import '../features/onboarding/pin_setup_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import 'extra_routes.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// All screens (TRD 14: 4 tabs in a shell; everything else pushed on top).
final routerProvider = Provider<GoRouter>((ref) {
  final lock = ref.watch(lockControllerProvider);
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/pin/create', builder: (_, _) => const PinSetupScreen()),
      GoRoute(path: '/fingerprint', builder: (_, _) => const FingerprintScreen()),
      GoRoute(path: '/opening', builder: (_, _) => const OpeningBalanceScreen()),
      GoRoute(path: '/contacts-permission', builder: (_, _) => const ContactsPermissionScreen()),
      GoRoute(path: '/unlock', builder: (_, state) => LockScreen(returnTo: state.uri.queryParameters['to'] ?? '/home')),
      GoRoute(path: '/dev/gallery', builder: (_, _) => const GalleryScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/contacts', builder: (_, _) => const ContactsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/charts', builder: (_, _) => const ChartsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/emi', builder: (_, _) => const EmiBillsScreen())]),
        ],
      ),
      ...extraRoutes,
    ],
  );
  lock.onLockNeeded = () {
    final here = router.state.uri.toString();
    if (!here.startsWith('/unlock')) router.go(Uri(path: '/unlock', queryParameters: {'to': here}).toString());
  };
  ref.onDispose(router.dispose);
  return router;
});
