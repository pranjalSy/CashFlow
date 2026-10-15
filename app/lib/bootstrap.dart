import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/flavor.dart';
import 'core/prefs.dart';
import 'data/local/local_store.dart';
import 'data/providers.dart';
import 'data/repositories/local_writer.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(flavor);
  final store = LocalStore();
  final db = await store.open();
  final userId = await localUserId(db);
  final prefs = UiPrefs(await SharedPreferences.getInstance());
  runApp(ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      databaseProvider.overrideWithValue(db),
      userIdProvider.overrideWithValue(userId),
      uiPrefsProvider.overrideWithValue(prefs),
    ],
    child: const CashFlowApp(),
  ));
}
