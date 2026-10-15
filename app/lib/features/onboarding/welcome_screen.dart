import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_page.dart';

/// Login / Sign up (screen 02). Account login comes in Phase D (T16); until then both
/// buttons continue on this phone and say so plainly.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return AppPage(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/logo.png', width: 88, height: 88, excludeFromSemantics: true),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.welcomeTitle, textAlign: TextAlign.center, style: t.displaySmall?.copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.welcomeBody,
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: c.textSecondary),
              ),
              const Spacer(flex: 2),
              AppButton(label: l.welcomeSignUp, onPressed: () => context.go('/language')),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: l.welcomeLogin, kind: AppButtonKind.secondary, onPressed: () => context.go('/language')),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.welcomeOfflineNote,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
