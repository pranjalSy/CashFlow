import 'package:flutter/material.dart';

import '../core/config/flavor.dart';
import '../core/theme/app_theme.dart';
import 'theme_preview.dart';

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
      home: const ThemePreview(),
    );
  }
}
