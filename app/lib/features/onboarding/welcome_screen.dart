import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';

/// Login / Sign up (screen 02): logo, heading, three promises, two buttons. Account login comes in
/// Phase D (T16); until then both buttons continue on this phone and the note says so plainly.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    Widget feature(IconData icon, String title, String sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            IconTile(icon: icon, color: c.brandText, tint: c.brandTint, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(sub, style: t.bodySmall),
              ]),
            ),
          ]),
        );
    return AppPage(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // Logo, heading, text, card and buttons rise in one after another (screen 02 animation note).
                      FadeSlideIn(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: ShapeDecoration(
                              shape: AppShapes.squircle(20),
                              shadows: [BoxShadow(color: c.brandButton.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -6)],
                            ),
                            child: ClipRSuperellipse(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset('assets/images/logo.png', width: 64, height: 64, excludeFromSemantics: true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(index: 1, child: Text(l.welcomeTitle, style: t.displaySmall?.copyWith(fontSize: 28, height: 1.15))),
                      const SizedBox(height: AppSpacing.xs),
                      FadeSlideIn(index: 2, child: Text(l.welcomeBody, style: t.bodyLarge?.copyWith(color: c.textSecondary, height: 1.45))),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        index: 3,
                        child: AppCard(
                          radius: AppRadii.lg,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(children: [
                            feature(LucideIcons.bell, l.welcomeF1, l.welcomeF1Sub),
                            Divider(height: 1, color: c.border),
                            feature(LucideIcons.activity, l.welcomeF2, l.welcomeF2Sub),
                            Divider(height: 1, color: c.border),
                            feature(LucideIcons.lock, l.welcomeF3, l.welcomeF3Sub),
                          ]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(index: 4, child: AppButton(label: l.welcomeSignUp, onPressed: () => context.go('/language'))),
                      const SizedBox(height: AppSpacing.xs),
                      FadeSlideIn(
                        index: 5,
                        child: _OutlineButton(label: l.welcomeLogin, onPressed: () => context.go('/language')),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l.welcomeOfflineNote, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White pill with a thin border (secondary action, screen 02).
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = AppShapes.squircle(AppRadii.pill, side: BorderSide(color: c.border));
    return Semantics(
      button: true,
      container: true,
      child: Pressable(
        child: Material(
          color: c.card,
          shape: shape,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            child: SizedBox(
              height: 52,
              child: Center(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.text))),
            ),
          ),
        ),
      ),
    );
  }
}
