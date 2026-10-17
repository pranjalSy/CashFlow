import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/security/biometric_service.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import 'onboarding_scaffold.dart';

/// Fingerprint only (C5, FR-L3/L4). No sensor → skipped; sensor without a finger → "Set up first".
class FingerprintScreen extends ConsumerStatefulWidget {
  const FingerprintScreen({super.key, this.next = '/opening'});

  final String next;

  @override
  ConsumerState<FingerprintScreen> createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends ConsumerState<FingerprintScreen> {
  FingerprintState? _state;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(biometricServiceProvider).state();
    if (!mounted) return;
    if (s == FingerprintState.unavailable) {
      context.go(widget.next);
      return;
    }
    setState(() => _state = s);
  }

  Future<void> _enable() async {
    final bio = ref.read(biometricServiceProvider);
    final ok = await bio.authenticate(context.l10n.fingerprintReason);
    if (!mounted) return;
    if (ok) {
      await bio.setEnabled(true);
      if (mounted) setState(() => _done = true); // "Fingerprint is on" (screen 07, second state)
    } else {
      setState(() => _error = context.l10n.fingerprintFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final s = _state;
    if (s == null) return const OnboardingScaffold(step: 1, child: SizedBox.shrink());
    final ready = s == FingerprintState.ready;
    if (_done) {
      return OnboardingScaffold(
        step: 1,
        bottom: AppButton(label: l.continueLabel, onPressed: () => context.go(widget.next)),
        child: Column(children: [
          const SizedBox(height: AppSpacing.xl),
          FadeSlideIn(
            child: Container(
              width: 150,
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.incomeTint),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.incomeButton,
                  boxShadow: [BoxShadow(color: c.incomeButton.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -6)],
                ),
                child: Icon(LucideIcons.check, size: 44, color: c.onButton),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.fingerprintOnTitle, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l.fingerprintOnBody, textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.fingerprintOnNote, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
        ]),
      );
    }
    Widget point(IconData icon, String title, String sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            IconTile(icon: icon, color: c.brandText, tint: c.brandTint, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(sub, style: t.bodySmall),
              ]),
            ),
          ]),
        );
    return OnboardingScaffold(
      step: 1,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ready) AppButton(label: l.fingerprintEnable, icon: LucideIcons.fingerprint, onPressed: _enable),
          if (ready) const SizedBox(height: AppSpacing.xs),
          if (ready)
            TextButton(onPressed: () => context.go(widget.next), child: Text(l.notNow, style: TextStyle(color: c.textSecondary)))
          else
            AppButton(label: l.continueLabel, kind: AppButtonKind.secondary, onPressed: () => context.go(widget.next)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          if (ready)
            BreathingRings(color: c.brandText, child: const HeroIcon(icon: LucideIcons.fingerprint, size: 96))
          else
            const HeroIcon(icon: LucideIcons.fingerprint, size: 96),
          const SizedBox(height: AppSpacing.sm),
          Text(ready ? l.fingerprintTitle : l.fingerprintNotSetTitle, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ready ? l.fingerprintBody : l.fingerprintNotSetBody,
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: c.textSecondary),
          ),
          if (ready) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              radius: AppRadii.lg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(children: [
                FadeSlideIn(index: 1, child: point(LucideIcons.zap, l.fpFaster, l.fpFasterSub)),
                Divider(height: 1, color: c.border),
                FadeSlideIn(index: 2, child: point(LucideIcons.keyRound, l.fpPinBackup, l.fpPinBackupSub)),
                Divider(height: 1, color: c.border),
                FadeSlideIn(index: 3, child: point(LucideIcons.eyeOff, l.fpNeverSee, l.fpNeverSeeSub)),
              ]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.expense, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
