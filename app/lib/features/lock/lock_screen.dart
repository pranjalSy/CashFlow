import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/security/pin_service.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/pin_pad.dart';
import 'lock_controller.dart';

/// Unlock: fingerprint first if enabled, PIN as second option and fallback (FR-L5).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.returnTo = '/home'});

  final String returnTo;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  bool _fingerprint = false;
  Duration? _locked;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final locked = await ref.read(pinServiceProvider).lockedFor();
    if (locked != null) _countdown(locked);
    final bio = ref.read(biometricServiceProvider);
    final enabled = await bio.isEnabled();
    if (!mounted) return;
    setState(() => _fingerprint = enabled);
    if (enabled) await _tryFingerprint();
  }

  Future<void> _tryFingerprint() async {
    final ok = await ref.read(biometricServiceProvider).authenticate(context.l10n.fingerprintReason);
    if (ok) {
      _unlocked();
    } else if (mounted) {
      setState(() => _error = context.l10n.fingerprintFailed);
    }
  }

  void _countdown(Duration d) {
    _timer?.cancel();
    setState(() => _locked = d);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = (_locked ?? Duration.zero) - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        t.cancel();
        if (mounted) setState(() => _locked = null);
      } else if (mounted) {
        setState(() => _locked = left);
      }
    });
  }

  Future<void> _onPin(String pin) async {
    final r = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    switch (r.outcome) {
      case PinOutcome.ok:
        _unlocked();
      case PinOutcome.wrong:
        setState(() => _error = context.l10n.pinWrong(r.triesLeft!));
      case PinOutcome.locked:
        setState(() => _error = null);
        _countdown(r.lockedFor!);
      case PinOutcome.noPin:
        context.go('/pin/create');
    }
  }

  void _unlocked() {
    ref.read(lockControllerProvider).markUnlocked();
    if (mounted) context.go(widget.returnTo);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final lockedText = _locked == null ? null : l.pinLocked(_locked!.inSeconds.clamp(1, 99999));
    return PopScope(
      canPop: false,
      child: AppPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 600;
                return Column(
                  children: [
                    SizedBox(height: compact ? 0 : AppSpacing.lg),
                    if (!compact)
                      ClipRSuperellipse(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/images/logo.png', width: 64, height: 64, excludeFromSemantics: true),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l.pinEnterTitle, style: t.headlineSmall),
                    const Spacer(),
                    PinPad(onComplete: _onPin, error: lockedText ?? _error, enabled: _locked == null, keyHeight: compact ? 46 : 58),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => showAppPopup<void>(
                            context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.pinForgot, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l.pinForgotBody,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
                              ],
                            ),
                          ),
                          child: Text(l.pinForgot),
                        ),
                        if (_fingerprint)
                          TextButton.icon(
                            onPressed: _locked == null ? _tryFingerprint : null,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(l.useFingerprint),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
