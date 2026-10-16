import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import 'onboarding_scaffold.dart';

/// Explain first, then ask (screen 09). Either answer finishes first run and opens Home.
class ContactsPermissionScreen extends ConsumerWidget {
  const ContactsPermissionScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref, {required bool ask}) async {
    if (ask) await ref.read(contactsAccessProvider).request();
    await ref.read(profileRepositoryProvider).finishOnboarding(language: ref.read(localeProvider)?.languageCode ?? 'en');
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    Widget point(IconData icon, String title, String sub) => ListRowTile(
      leading: IconTile(icon: icon, color: c.brandText, tint: c.brandTint, size: 36),
      title: title,
      subtitle: sub,
    );
    return OnboardingScaffold(
      step: 3,
      onBack: () => context.go('/opening'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: l.contactsPermAllow, onPressed: () => _finish(context, ref, ask: true)),
          TextButton(onPressed: () => _finish(context, ref, ask: false), child: Text(l.notNow)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Floating(child: HeroIcon(icon: Icons.people_alt_outlined)),
          const SizedBox(height: AppSpacing.lg),
          Text(l.contactsPermTitle, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.contactsPermBody,
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: Column(
              children: [
                FadeSlideIn(index: 1, child: point(Icons.touch_app_outlined, l.contactsPermPoint1, l.contactsPermPoint1Sub)),
                FadeSlideIn(index: 2, child: point(Icons.smartphone_outlined, l.contactsPermPoint2, l.contactsPermPoint2Sub)),
                FadeSlideIn(index: 3, child: point(Icons.cloud_outlined, l.contactsPermPoint3, l.contactsPermPoint3Sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
