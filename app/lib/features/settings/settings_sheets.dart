import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/security/biometric_service.dart';
import '../../core/services.dart';
import '../../core/system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import 'settings_controller.dart';

/// Pick one value (language, theme, default reminder, lock after). Returns the choice, or null.
Future<T?> showChoiceSheet<T>(BuildContext context, {required String title, required List<(T, String)> options, required T selected, String? note}) {
  return showAppSheet<T>(
    context,
    builder: (context) {
      final c = context.colors;
      final t = Theme.of(context).textTheme;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, textAlign: TextAlign.center, style: t.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final (value, label) in options)
          Semantics(
            selected: value == selected,
            child: InkWell(
              customBorder: AppShapes.squircle(AppRadii.sm),
              onTap: () => Navigator.pop(context, value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(children: [
                  const SizedBox(width: 6),
                  Expanded(child: Text(label, style: t.titleSmall?.copyWith(fontWeight: value == selected ? FontWeight.w700 : FontWeight.w600))),
                  if (value == selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandButton),
                      child: Icon(LucideIcons.check, size: 15, color: c.onButton),
                    ),
                  const SizedBox(width: 6),
                ]),
              ),
            ),
          ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(note, textAlign: TextAlign.center, style: t.bodySmall),
        ],
      ]);
    },
  );
}

/// App lock (FR-L8): change PIN and fingerprint on/off. Fingerprint turns on only after one
/// successful system check (FR-L4); only fingerprint is used, never face (C5).
Future<void> showAppLockSheet(BuildContext context) => showAppSheet<void>(context, builder: (_) => const _AppLockSheet());

class _AppLockSheet extends ConsumerStatefulWidget {
  const _AppLockSheet();

  @override
  ConsumerState<_AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends ConsumerState<_AppLockSheet> {
  FingerprintState? _state;

  @override
  void initState() {
    super.initState();
    ref.read(biometricServiceProvider).state().then((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  Future<void> _setFingerprint(bool on) async {
    final bio = ref.read(biometricServiceProvider);
    if (on && !await bio.authenticate(context.l10n.fingerprintReason)) return;
    await bio.setEnabled(on);
    ref.invalidate(fingerprintOnProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final on = ref.watch(fingerprintOnProvider).value ?? false;
    final state = _state;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.appLock, textAlign: TextAlign.center, style: t.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      ListRowTile(
        leading: IconTile(icon: LucideIcons.keyRound, color: c.textSecondary, tint: c.raised, size: 34),
        title: l.changePin,
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
        onTap: () {
          Navigator.pop(context);
          context.push('/settings/pin');
        },
      ),
      if (on || state == FingerprintState.ready)
        ListRowTile(
          leading: IconTile(icon: LucideIcons.fingerprint, color: c.textSecondary, tint: c.raised, size: 34),
          title: l.fingerprintUnlock,
          trailing: AppToggle(value: on, onChanged: _setFingerprint),
          onTap: () => _setFingerprint(!on),
        )
      else if (state == FingerprintState.notEnrolled)
        ListRowTile(
          leading: IconTile(icon: LucideIcons.fingerprint, color: c.textSecondary, tint: c.raised, size: 34),
          title: l.fingerprintNotSetTitle,
          subtitle: l.fingerprintNotSetBody,
        ),
    ]);
  }
}

/// "Log out?" (screen 24): says plainly that everything on this phone is erased.
/// The erase itself comes with account login (T21); for now the sheet only explains.
Future<void> showLogOutSheet(BuildContext context) => showAppSheet<void>(
      context,
      builder: (context) {
        final l = context.l10n;
        final c = context.colors;
        final t = Theme.of(context).textTheme;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          IconTile(icon: LucideIcons.logOut, color: c.expense, tint: c.expenseTint, size: 58),
          const SizedBox(height: AppSpacing.sm),
          Text(l.logOutTitle, textAlign: TextAlign.center, style: t.titleLarge),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: l.logOutBodyStrong, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
              TextSpan(text: l.logOutBody),
            ]),
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: AppButton(label: l.cancel, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppButton(label: l.logOut, kind: AppButtonKind.danger, onPressed: () => Navigator.pop(context))),
          ]),
        ]);
      },
    );

/// "Reminders not coming?" (FR-R5): battery and auto-start steps for Realme-like phones,
/// with a button to this app's page in the phone settings.
Future<void> showRemindersHelpSheet(BuildContext context, WidgetRef ref) => showAppSheet<void>(
      context,
      builder: (context) {
        final l = context.l10n;
        final c = context.colors;
        final t = Theme.of(context).textTheme;
        Widget step(int n, String text) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandTint),
                  child: Text('$n', style: t.labelMedium?.copyWith(color: c.brandText, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(text, style: t.bodyMedium?.copyWith(color: c.text)))),
              ]),
            );
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: IconTile(icon: LucideIcons.bellRing, color: c.brandText, tint: c.brandTint, size: 58)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.remindersHelp, textAlign: TextAlign.center, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(l.remindersHelpBody, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          step(1, l.remindersStepBattery),
          step(2, l.remindersStepAutoStart),
          step(3, l.remindersStepNotifications),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: l.openPhoneSettings, icon: LucideIcons.settings, onPressed: () => ref.read(systemServiceProvider).openAppSettings()),
        ]);
      },
    );
