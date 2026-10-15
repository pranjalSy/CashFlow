import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/flavor.dart';
import '../core/l10n.dart';
import '../core/prefs.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class CashFlowApp extends ConsumerWidget {
  const CashFlowApp({super.key, this.themeMode});

  /// Forces a theme (tests); otherwise the saved preference, default System (T14 adds the switch).
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = FlavorConfig.instance;
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode ?? ref.watch(uiPrefsProvider).themeMode,
      locale: ref.watch(localeProvider),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
