import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/app_page.dart';

/// Shared layout for first-run screens: back, progress dashes, content, bottom actions.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({super.key, required this.child, this.step, this.steps = 4, this.onBack, this.bottom, this.scroll = true, this.trailing});

  final Widget child;

  /// 0-based progress step (dashes on top), or null for none.
  final int? step;
  final int steps;
  final VoidCallback? onBack;
  final Widget? bottom;
  final bool scroll;

  /// Top-right action (for example "Skip", screen 08).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: child,
    );
    return AppPage(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    if (onBack != null)
                      HeaderButton(icon: LucideIcons.chevronLeft, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onTap: onBack)
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: step == null
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < steps; i++)
                                  Container(
                                    width: 22,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: ShapeDecoration(
                                      color: i <= step! ? c.brandButton : c.border,
                                      shape: AppShapes.squircle(AppRadii.pill),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    trailing ?? const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(child: scroll ? SingleChildScrollView(child: body) : body),
            if (bottom != null)
              Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md), child: bottom),
          ],
        ),
      ),
    );
  }
}

/// Big centred icon box used on first-run screens.
class HeroIcon extends StatelessWidget {
  const HeroIcon({super.key, required this.icon, this.size = 88});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.card,
          shape: AppShapes.squircle(size * 0.32),
          shadows: [
            BoxShadow(color: c.brandButton.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -12),
          ],
        ),
        child: Icon(icon, size: size * 0.45, color: c.brandText),
      ),
    );
  }
}
