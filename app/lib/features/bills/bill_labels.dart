import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';

/// Icon, colour and name for each bill type (FR-B1: each type has its own icon and colour).
IconData billIcon(String type) => switch (type) {
      'electricity' => LucideIcons.zap,
      'gas' => LucideIcons.flame,
      'mobile' => LucideIcons.smartphone,
      'internet' => LucideIcons.wifi,
      'dth' => LucideIcons.monitor,
      'water' => LucideIcons.droplet,
      'insurance' => LucideIcons.shield,
      _ => LucideIcons.ellipsis,
    };

(Color, Color) billColors(BuildContext context, String type) {
  final c = context.colors;
  return switch (type) {
    'electricity' => (c.premium, c.premiumTint),
    'gas' => (c.dueSoon, c.dueSoonTint),
    'mobile' => (c.income, c.incomeTint),
    'internet' => (c.lent, c.lentTint),
    'dth' => (c.lent, c.lentTint),
    'water' => (c.brandText, c.brandTint),
    'insurance' => (c.borrowed, c.borrowedTint),
    _ => (c.textSecondary, c.raised),
  };
}

String billTypeName(AppLocalizations l, String type) => switch (type) {
      'electricity' => l.billElectricity,
      'gas' => l.billGas,
      'mobile' => l.billMobile,
      'internet' => l.billInternet,
      'dth' => l.billDth,
      'water' => l.billWater,
      'insurance' => l.billInsurance,
      _ => l.billOther,
    };
