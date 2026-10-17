import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'app_button.dart';
import 'app_card.dart';

/// One style for every empty list (FR-U8, screen 28): raised icon tile with a small "+" badge,
/// a title, one line, and an optional button. No card behind it.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction, this.badge = true});

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The blue "+" on the tile; off where nothing can be added (for example no search results).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 94,
            child: Stack(clipBehavior: Clip.none, children: [
              SizedBox.square(
                dimension: 86,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: dark ? c.raised : c.card,
                    shape: AppShapes.squircle(28),
                    shadows: dark ? null : [BoxShadow(color: c.brandButton.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 12), spreadRadius: -12)],
                  ),
                  child: Icon(icon, size: 34, color: c.brandText),
                ),
              ),
              if (badge)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandButton, border: Border.all(color: c.page, width: 3)),
                    child: Icon(LucideIcons.plus, size: 16, color: c.onButton),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: actionLabel!, onPressed: onAction!, expand: false, height: 48, icon: LucideIcons.plus),
          ],
        ],
      ),
    );
  }
}

/// Small grey bar shown while offline (FR-S8).
class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: ShapeDecoration(color: const Color(0xFF5B6B7F), shape: AppShapes.squircle(AppRadii.pill)),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.cloudOff, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Green toast "Back online · all synced", shown 2 s after a successful sync (FR-S8, screen 28).
/// Connected to the internet check and the sync engine in T17.
class BackOnlineToast extends StatelessWidget {
  const BackOnlineToast({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: c.incomeButton,
        shape: AppShapes.squircle(AppRadii.pill),
        shadows: [BoxShadow(color: c.incomeButton.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.check, size: 15, color: c.onButton),
        const SizedBox(width: 7),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.onButton))),
      ]),
    );
  }
}

/// Card over a blurred, locked Premium screen (screen 28, FR-P9 amber).
class PremiumLockCard extends StatelessWidget {
  const PremiumLockCard({super.key, required this.title, required this.message, required this.buttonLabel, required this.fineprint, required this.onTry});

  final String title;
  final String message;
  final String buttonLabel;
  final String fineprint;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: c.sheet,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 56,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: c.premiumTint, shape: AppShapes.squircle(18)),
              child: Icon(LucideIcons.lock, color: c.premium, size: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, textAlign: TextAlign.center, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: buttonLabel, onPressed: onTry, kind: AppButtonKind.premium, icon: LucideIcons.award),
          const SizedBox(height: AppSpacing.xs),
          Text(fineprint, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}
