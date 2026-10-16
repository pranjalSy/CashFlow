import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/security/biometric_service.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/app_button.dart';
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
      if (mounted) context.go(widget.next);
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
    return OnboardingScaffold(
      step: 1,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ready) AppButton(label: l.fingerprintEnable, icon: Icons.fingerprint_rounded, onPressed: _enable),
          if (ready) const SizedBox(height: AppSpacing.xs),
          AppButton(label: ready ? l.notNow : l.continueLabel, kind: AppButtonKind.secondary, onPressed: () => context.go(widget.next)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          if (ready)
            BreathingRings(color: c.brandText, child: const HeroIcon(icon: Icons.fingerprint_rounded, size: 110))
          else
            const HeroIcon(icon: Icons.fingerprint_rounded, size: 110),
          const SizedBox(height: AppSpacing.lg),
          Text(ready ? l.fingerprintTitle : l.fingerprintNotSetTitle, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ready ? l.fingerprintBody : l.fingerprintNotSetBody,
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: c.textSecondary),
          ),
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
