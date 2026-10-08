import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/flavor.dart';

void bootstrap(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(flavor);
  runApp(const CashFlowApp());
}
