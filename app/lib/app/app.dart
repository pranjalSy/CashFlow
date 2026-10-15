import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/flavor.dart';
import '../core/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/dev/gallery_screen.dart';

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key, this.themeMode = ThemeMode.system});

  /// Follows the phone setting until Settings → Theme exists (T14).
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const GalleryScreen(),
    );
  }
}
