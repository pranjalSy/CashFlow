import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/pin_pad.dart';
import 'onboarding_scaffold.dart';

/// Create PIN, then confirm it (FR-L1). Moves on by itself after 4 digits (C4).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.next = '/fingerprint'});

  final String next;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = context.l10n.pinMismatch;
      });
      return;
    }
    await ref.read(pinServiceProvider).setPin(pin);
    if (mounted) context.go(widget.next);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final confirming = _first != null;
    return OnboardingScaffold(
      step: 0,
      scroll: false,
      onBack: confirming ? () => setState(() => _first = null) : () => context.go('/language'),
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxHeight < 600;
          return Column(
            children: [
              if (!compact) ...[
                const SizedBox(height: AppSpacing.md),
                const HeroIcon(icon: LucideIcons.lock, size: 72),
                const SizedBox(height: AppSpacing.md),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(confirming),
                  children: [
                    Text(confirming ? l.pinConfirmTitle : l.pinCreateTitle, textAlign: TextAlign.center, style: t.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      confirming ? l.pinConfirmBody : l.pinCreateBody,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PinPad(key: ValueKey(confirming), onComplete: _onPin, error: _error, keyHeight: compact ? 46 : 58),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }
}
