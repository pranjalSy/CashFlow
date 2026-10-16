import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'app_button.dart';
import 'app_card.dart';

/// One style for every empty list (FR-U8): icon, title, one line, optional button.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 84,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(28)),
              child: Icon(icon, size: 34, color: c.brandText),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(label: actionLabel!, onPressed: onAction!, expand: false, icon: Icons.add_rounded),
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
          const Icon(Icons.cloud_off_outlined, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
          ),
        ],
      ),
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
              child: Icon(Icons.lock_outline_rounded, color: c.premium, size: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, textAlign: TextAlign.center, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: buttonLabel, onPressed: onTry, kind: AppButtonKind.premium, icon: Icons.workspace_premium_outlined),
          const SizedBox(height: AppSpacing.xs),
          Text(fineprint, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}
