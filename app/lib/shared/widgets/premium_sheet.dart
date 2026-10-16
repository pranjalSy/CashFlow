import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'app_button.dart';
import 'overlays.dart';

/// Small paywall sheet when a Free user taps a Premium item (FR-P7). The user's work is never lost.
/// Purchase arrives in T20; until then "Try Premium" explains that.
Future<void> showPremiumSheet(BuildContext context, {required IconData icon, required String title, required String body, String? footnote}) {
  final l = context.l10n;
  return showAppSheet<void>(
    context,
    builder: (context) {
      final c = context.colors;
      final t = Theme.of(context).textTheme;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          SizedBox.square(
            dimension: 62,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: c.borrowedTint, shape: AppShapes.squircle(20)),
              child: Icon(icon, size: 28, color: c.borrowed),
            ),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: c.premiumButton, shape: BoxShape.circle, border: Border.all(color: c.sheet, width: 2)),
              child: const Icon(Icons.workspace_premium_outlined, size: 13, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(title, textAlign: TextAlign.center, style: t.titleLarge),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l.premiumTryButton,
          kind: AppButtonKind.premium,
          onPressed: () {
            Navigator.pop(context);
            CompactSnackbar.show(context, message: l.premiumComingLater);
          },
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.notNow)),
        if (footnote != null) Text(footnote, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
      ]);
    },
  );
}

/// Small amber "Premium" tag next to locked fields.
class PremiumTag extends StatelessWidget {
  const PremiumTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(color: c.premiumTint, shape: AppShapes.squircle(AppRadii.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium_outlined, size: 11, color: c.premium),
        const SizedBox(width: 3),
        Text(context.l10n.premium, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.premium, fontSize: 10)),
      ]),
    );
  }
}
