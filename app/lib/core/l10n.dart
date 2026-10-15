import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// App languages (DESIGN_DECISIONS C2): 13 are listed, only these 3 work at launch.
const supportedAppLocales = [Locale('en'), Locale('hi'), Locale('gu')];

extension L10nContext on BuildContext {
  /// Localized strings for the current language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
