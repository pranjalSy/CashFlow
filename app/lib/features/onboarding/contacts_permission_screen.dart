import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
          TextButton(onPressed: () => _finish(context, ref, ask: false), child: Text(l.notNow, style: TextStyle(color: c.textSecondary))),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const _PeopleArt(),
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
                FadeSlideIn(index: 1, child: point(LucideIcons.pointer, l.contactsPermPoint1, l.contactsPermPoint1Sub)),
                Divider(height: 1, color: c.border),
                FadeSlideIn(index: 2, child: point(LucideIcons.smartphone, l.contactsPermPoint2, l.contactsPermPoint2Sub)),
                Divider(height: 1, color: c.border),
                FadeSlideIn(index: 3, child: point(LucideIcons.cloud, l.contactsPermPoint3, l.contactsPermPoint3Sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 09 picture: a blue ₹ tile with people around it and two small amounts; they float gently.
class _PeopleArt extends StatelessWidget {
  const _PeopleArt();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    Widget avatar(String text, Color fg, Color bg, double size) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: c.card, width: 3),
            boxShadow: [BoxShadow(color: c.text.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Text(text, style: t.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800)),
        );
    Widget chip(String text, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: ShapeDecoration(color: c.card, shape: AppShapes.squircle(AppRadii.pill), shadows: [BoxShadow(color: c.text.withValues(alpha: 0.08), blurRadius: 8)]),
          child: Text(text, style: t.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
        );
    Widget at(double x, double y, Widget child, {double d = 5}) => Positioned(left: x, top: y, child: Floating(distance: d, child: child));
    return SizedBox(
      width: 280,
      height: 180,
      child: Stack(children: [
        at(10, 0, chip('+₹3,000', c.lent), d: 3),
        at(26, 30, avatar('RS', c.lent, c.lentTint, 56)),
        at(180, 16, avatar('AP', c.borrowed, c.borrowedTint, 52), d: 6),
        at(48, 122, avatar('VM', c.lent, c.brandTint, 48), d: 4),
        at(128, 138, avatar('NK', c.premium, c.premiumTint, 44), d: 6),
        at(208, 100, avatar('PD', c.income, c.incomeTint, 52), d: 5),
        at(198, 152, chip('−₹2,000', c.borrowed), d: 3),
        Positioned(
          left: 106,
          top: 48,
          child: Container(
            width: 68,
            height: 68,
            decoration: ShapeDecoration(
              color: c.brandButton,
              shape: AppShapes.squircle(20),
              shadows: [BoxShadow(color: c.brandButton.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -6)],
            ),
            child: Icon(LucideIcons.indianRupee, color: c.onButton, size: 32),
          ),
        ),
      ]),
    );
  }
}
