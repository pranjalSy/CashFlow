import 'package:flutter/material.dart';

import '../core/config/flavor.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_typography.dart';

/// Temporary dev screen to check theme tokens on a phone (T01).
/// Replaced by the widget gallery (T02) and the real Home (T08).
/// Texts are sample content only; real screens take text from ARB files (T03).
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text(config.appName, style: t.displaySmall),
            Text('Flavor: ${config.flavor.name}', style: t.bodySmall),
            const SizedBox(height: AppSpacing.md),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance at end of October', style: t.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('₹1,20,000', style: AppTypography.amount(36, color: c.text)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: _Tile('Income', '+₹45,000', c.income, c.incomeTint)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _Tile('Expense', '−₹28,500', c.expense, c.expenseTint)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _Tile('Lent', '₹5,000', c.lent, c.lentTint)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _Tile('Borrowed', '₹2,000', c.borrowed, c.borrowedTint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track every rupee', style: t.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('हिंदी: उधार · रिमाइंडर · ₹2,450', style: t.bodyLarge),
                  Text('ગુજરાતી: ઉધાર · રિમાઇન્ડર · ₹2,450', style: t.bodyLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Secondary text', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                  Text('Muted hint', style: t.bodyMedium?.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Pill('Save', c.brandButton, c.onButton),
                _Pill('Paid', c.incomeButton, c.onButton),
                _Pill('Delete', c.expenseButton, c.onButton),
                _Pill('Try Premium', c.premiumButton, c.onButton),
                _Pill('Due in 3 days', c.dueSoonTint, c.dueSoon),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.glassCard,
        shape: AppShapes.squircle(AppRadii.lg, side: BorderSide(color: c.glassEdge)),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.amount, this.color, this.tint);

  final String label;
  final String amount;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(AppRadii.sm)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(amount, maxLines: 1, style: AppTypography.amount(16, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: background, shape: AppShapes.squircle(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground)),
      ),
    );
  }
}
