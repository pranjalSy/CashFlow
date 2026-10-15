import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/flavor.dart';

void bootstrap(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(flavor);
  runApp(const ProviderScope(child: CashFlowApp()));
}
