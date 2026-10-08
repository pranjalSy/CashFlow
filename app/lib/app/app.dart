import 'package:flutter/material.dart';

import '../core/config/flavor.dart';

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5AB7F1)),
        scaffoldBackgroundColor: const Color(0xFFFAFCFF),
      ),
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary screen until the real Home screen (T10) is built.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(config.appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Flavor: ${config.flavor.name}'),
          ],
        ),
      ),
    );
  }
}
