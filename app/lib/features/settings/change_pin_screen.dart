import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/security/pin_service.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/pin_pad.dart';
import '../onboarding/onboarding_scaffold.dart';

enum _Step { current, fresh, confirm }

/// Change PIN (FR-L8): current PIN first (same tries and wait as the lock screen, FR-L7),
/// then the new PIN twice. Each step moves on by itself after 4 digits (C4).
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _Step _step = _Step.current;
  String? _fresh;
  String? _error;

  Future<void> _onPin(String pin) async {
    final l = context.l10n;
    final pins = ref.read(pinServiceProvider);
    switch (_step) {
      case _Step.current:
        final r = await pins.verify(pin);
        if (!mounted) return;
        setState(() {
          switch (r.outcome) {
            case PinOutcome.ok:
            case PinOutcome.noPin:
              _step = _Step.fresh;
              _error = null;
            case PinOutcome.wrong:
              _error = l.pinWrong(r.triesLeft!);
            case PinOutcome.locked:
              _error = l.pinLocked(r.lockedFor!.inSeconds.clamp(1, 99999));
          }
        });
      case _Step.fresh:
        setState(() {
          _fresh = pin;
          _step = _Step.confirm;
          _error = null;
        });
      case _Step.confirm:
        if (pin != _fresh) {
          setState(() {
            _fresh = null;
            _step = _Step.fresh;
            _error = l.pinMismatch;
          });
          return;
        }
        await pins.setPin(pin);
        if (!mounted) return;
        CompactSnackbar.show(context, message: l.pinChanged);
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final title = switch (_step) {
      _Step.current => l.pinCurrentTitle,
      _Step.fresh => l.pinNewTitle,
      _Step.confirm => l.pinConfirmTitle,
    };
    return AppPage(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.md),
          child: LayoutBuilder(builder: (context, box) {
            final compact = box.maxHeight < 600;
            return Column(children: [
              Row(children: [
                HeaderButton(icon: LucideIcons.chevronLeft, tooltip: l.back, onTap: () => context.pop()),
                Expanded(child: Center(child: Text(l.changePin, style: t.titleLarge))),
                const SizedBox(width: 48),
              ]),
              if (!compact) ...[
                const SizedBox(height: AppSpacing.lg),
                const HeroIcon(icon: LucideIcons.keyRound, size: 68),
              ],
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(title, key: ValueKey(_step), textAlign: TextAlign.center, style: t.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: PinPad(
                  key: ValueKey(_step),
                  onComplete: _onPin,
                  error: _error,
                  expand: true,
                  keyHeight: compact ? 46 : 56,
                  hint: _step == _Step.fresh ? l.pinAvoidEasy : null,
                  footnote: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(LucideIcons.lock, size: 13, color: c.income),
                    const SizedBox(width: 6),
                    Flexible(child: Text(l.pinStoredOnPhone, style: t.labelSmall?.copyWith(color: c.income))),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
