import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/app_page.dart';

/// Logo + tagline, then first run or the lock screen (FR-A5).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final done = await ref.read(profileRepositoryProvider).onboardingDone();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(done ? '/unlock' : '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppPage(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.85) / 0.15).clamp(0, 1),
            child: Transform.scale(scale: v, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRSuperellipse(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/images/logo.png', width: 112, height: 112, semanticLabel: context.l10n.appName),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.appName, style: t.displaySmall),
              const SizedBox(height: 4),
              Text(context.l10n.tagline, style: t.bodyLarge?.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
