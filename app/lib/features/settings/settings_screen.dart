import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/flavor.dart';
import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/glass.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/overlays.dart';
import '../lock/lock_controller.dart';
import '../onboarding/language_screen.dart';
import 'settings_controller.dart';
import 'settings_sheets.dart';

/// Settings (FR-G1, screen 24), opened from the Home avatar. Rows that need the account or the
/// cloud (Devices, Delete account, the log-out erase, Premium purchase) are connected in Phase D.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _playSubscriptions = 'https://play.google.com/store/account/subscriptions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final renews = ref.watch(planActiveUntilProvider).value;
    final theme = ref.watch(themeModeProvider);
    final reduceGlass = ref.watch(reduceGlassProvider);
    final fingerprint = ref.watch(fingerprintOnProvider).value ?? false;
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final version = ref.watch(appVersionProvider).value;
    final prefs = ref.read(uiPrefsProvider);
    final profiles = ref.read(profileRepositoryProvider);
    final language = ref.watch(localeProvider)?.languageCode ?? Localizations.localeOf(context).languageCode;
    final reminder = profile?.defaultReminderDays ?? 3;
    final lockAfter = prefs.lockAfterSeconds;

    String themeLabel(ThemeMode m) => switch (m) {
          ThemeMode.light => l.themeLight,
          ThemeMode.dark => l.themeDark,
          ThemeMode.system => l.themeSystem,
        };
    String reminderLabel(int d) => d == 0 ? l.onDueDay : l.daysBefore(d);
    String lockLabel(int s) => switch (s) {
          0 => l.lockImmediately,
          300 => l.lockFiveMinutes,
          _ => l.lockOneMinute,
        };
    Widget icon(IconData i, {Color? color, Color? tint}) => IconTile(icon: i, color: color ?? c.textSecondary, tint: tint ?? c.raised, size: 34);
    Widget value(String text) => Text(text, maxLines: 2, textAlign: TextAlign.end, style: t.labelLarge?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600));
    final chevron = Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted);
    Widget withChevron(String text) => Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: value(text)), const SizedBox(width: 6), chevron]);

    final children = <Widget>[
      // Profile: name and email arrive with account login (T16).
      AppCard(
        radius: AppRadii.lg - 2,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color.lerp(c.brandButton, Colors.white, 0.18)!, c.brandButton], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Text((profile?.name ?? 'CashFlow').characters.first.toUpperCase(), style: t.titleMedium?.copyWith(color: c.onButton, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(profile?.name ?? 'CashFlow', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        ]),
      ),
      const SizedBox(height: AppSpacing.xs),
      premium
          ? _PremiumCard(
              renews: renews == null ? null : l.planRenews(longDate(context, Ist.dateOf(renews))),
              onManage: () => ref.read(systemServiceProvider).openUrl(_playSubscriptions),
            )
          : _FreeCard(onTry: () => CompactSnackbar.show(context, message: l.premiumComingLater)),
      _Group(label: l.settingsGeneral, rows: [
        ListRowTile(
          leading: icon(LucideIcons.globe),
          title: l.settingsLanguage,
          trailing: withChevron(appLanguages.firstWhere((a) => a.code == language, orElse: () => appLanguages.first).native),
          onTap: () async {
            final code = await showChoiceSheet<String>(
              context,
              title: l.settingsLanguage,
              selected: language,
              options: [for (final a in appLanguages.where((a) => a.live)) (a.code, a.native)],
            );
            if (code == null) return;
            await ref.read(localeProvider.notifier).set(code);
            await profiles.setLanguage(code);
          },
        ),
        ListRowTile(
          leading: icon(LucideIcons.moon),
          title: l.settingsTheme,
          trailing: withChevron(themeLabel(theme)),
          onTap: () async {
            final m = await showChoiceSheet<ThemeMode>(
              context,
              title: l.settingsTheme,
              selected: theme,
              options: [for (final m in const [ThemeMode.system, ThemeMode.light, ThemeMode.dark]) (m, themeLabel(m))],
            );
            if (m != null) await ref.read(themeModeProvider.notifier).set(m);
          },
        ),
        ListRowTile(
          leading: icon(LucideIcons.bell),
          title: l.defaultReminder,
          trailing: withChevron(reminderLabel(reminder)),
          onTap: () async {
            final d = await showChoiceSheet<int>(
              context,
              title: l.defaultReminder,
              selected: reminder,
              note: l.defaultReminderNote,
              options: [for (final d in const [0, 3, 7]) (d, reminderLabel(d))],
            );
            if (d != null) await profiles.setDefaultReminder(d);
          },
        ),
        _ToggleRow(icon: icon(LucideIcons.eyeOff), title: l.hideAmountsNotif, value: profile?.hideAmounts ?? false, onChanged: profiles.setHideAmounts),
      ]),
      _Group(label: l.settingsSecurity, rows: [
        ListRowTile(
          leading: icon(LucideIcons.lock, color: c.brandText, tint: c.brandTint),
          title: l.appLock,
          trailing: withChevron(fingerprint ? l.pinAndFingerprint : l.pinOnly),
          onTap: () => showAppLockSheet(context),
        ),
        _StatefulLockAfter(label: l.lockAfter, icon: icon(LucideIcons.clock), labelFor: lockLabel, initial: lockAfter, chevron: withChevron),
        ListRowTile(leading: icon(LucideIcons.smartphone), title: l.devices, subtitle: l.devicesSub),
      ]),
      _Group(label: l.settingsData, rows: [
        ListRowTile(
          leading: icon(LucideIcons.refreshCw),
          title: l.syncLabel,
          subtitle: pending == 0 ? l.allBackedUp : l.changesOnPhone(pending),
          trailing: pending == 0
              ? Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.incomeTint),
                  child: Icon(LucideIcons.check, size: 13, color: c.income),
                )
              : Icon(LucideIcons.clock, size: 16, color: c.textMuted),
        ),
        ListRowTile(leading: icon(LucideIcons.download), title: l.exportData, subtitle: l.pdfOrCsv, trailing: chevron, onTap: () => context.push('/export')),
        ListRowTile(leading: icon(LucideIcons.chartColumn), title: l.budget, trailing: chevron, onTap: () => context.push('/budget')),
      ]),
      _Group(label: l.settingsDisplay, rows: [
        _ToggleRow(
          icon: icon(LucideIcons.droplet),
          title: l.reduceGlass,
          subtitle: l.reduceGlassSub,
          value: reduceGlass,
          onChanged: (v) async {
            ref.read(reduceGlassProvider.notifier).set(v);
            await prefs.setReduceGlass(v);
          },
        ),
        _ToggleRow(
          icon: icon(LucideIcons.chartColumn),
          title: l.shareUsage,
          subtitle: l.shareUsageSub,
          value: profile?.analyticsOptIn ?? true,
          onChanged: profiles.setAnalyticsOptIn,
        ),
      ]),
      _Group(label: l.settingsHelp, rows: [
        ListRowTile(
          leading: icon(LucideIcons.circleQuestionMark),
          title: l.remindersHelp,
          subtitle: l.remindersHelpSub,
          trailing: chevron,
          onTap: () => showRemindersHelpSheet(context, ref),
        ),
        // The policy page link is added with the release polish (T22).
        ListRowTile(leading: icon(LucideIcons.info), title: l.privacyPolicy),
      ]),
      _Group(label: l.settingsAccount, rows: [
        ListRowTile(
          leading: icon(LucideIcons.logOut, color: c.expense, tint: c.expenseTint),
          title: l.logOut,
          trailing: chevron,
          onTap: () => showLogOutSheet(context),
        ),
        ListRowTile(leading: icon(LucideIcons.trash2, color: c.expense, tint: c.expenseTint), title: l.deleteAccount, subtitle: l.deleteAccountSub),
      ], danger: true),
      if (FlavorConfig.instance.isDev)
        _Group(label: l.developer, rows: [
          _ToggleRow(icon: icon(LucideIcons.award), title: l.devPremiumToggle, value: premium, onChanged: ref.read(planRepositoryProvider).setPremiumForDev),
          ListRowTile(leading: icon(LucideIcons.layoutGrid), title: l.devGallery, trailing: chevron, onTap: () => context.push('/dev/gallery')),
        ]),
      if (version != null && version.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Text(l.versionLine(version), textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
        ),
    ];

    return AppPage(
      lightGlow: c.brandTint,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 0),
            child: Row(children: [
              HeaderButton(icon: LucideIcons.chevronLeft, tooltip: l.back, onTap: () => context.pop()),
              Expanded(child: Center(child: Text(l.settings, style: t.titleLarge))),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg + MediaQuery.paddingOf(context).bottom),
              children: [for (final (i, w) in children.indexed) FadeSlideIn(index: i, child: w)],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Grey group label + one card of rows with thin dividers (screen 24).
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.rows, this.danger = false});

  final String label;
  final List<Widget> rows;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, AppSpacing.md, 6, AppSpacing.xs),
        child: Text(label, style: t.labelMedium?.copyWith(color: c.textMuted, fontWeight: FontWeight.w700)),
      ),
      AppCard(
        radius: AppRadii.lg - 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.border),
            danger ? _DangerTitle(child: r) : r,
          ],
        ]),
      ),
    ]);
  }
}

/// Red row titles in the Account group (screen 24).
class _DangerTitle extends StatelessWidget {
  const _DangerTitle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final red = context.colors.expense;
    return Theme(
      data: theme.copyWith(textTheme: theme.textTheme.copyWith(titleSmall: theme.textTheme.titleSmall?.copyWith(color: red))),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.title, required this.value, required this.onChanged, this.subtitle});

  final Widget icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Long titles ("Hide amounts in notifications") wrap to two lines instead of being cut (screen 24).
    return Semantics(
      toggled: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: t.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                ]),
              ),
              AppToggle(value: value, onChanged: onChanged),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "Lock after": Immediately / 1 minute / 5 minutes, saved on this phone and used at once.
class _StatefulLockAfter extends ConsumerStatefulWidget {
  const _StatefulLockAfter({required this.label, required this.icon, required this.labelFor, required this.initial, required this.chevron});

  final String label;
  final Widget icon;
  final String Function(int seconds) labelFor;
  final int initial;
  final Widget Function(String value) chevron;

  @override
  ConsumerState<_StatefulLockAfter> createState() => _StatefulLockAfterState();
}

class _StatefulLockAfterState extends ConsumerState<_StatefulLockAfter> {
  late int _seconds = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ListRowTile(
      leading: widget.icon,
      title: widget.label,
      trailing: widget.chevron(widget.labelFor(_seconds)),
      onTap: () async {
        final s = await showChoiceSheet<int>(
          context,
          title: widget.label,
          selected: _seconds,
          options: [for (final s in const [0, 60, 300]) (s, widget.labelFor(s))],
        );
        if (s == null) return;
        await ref.read(uiPrefsProvider).setLockAfterSeconds(s);
        ref.read(lockControllerProvider).lockAfter = Duration(seconds: s);
        setState(() => _seconds = s);
      },
    );
  }
}

/// Premium: renewal date + Manage (Play subscriptions), brand gradient (screen 24).
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.renews, required this.onManage});

  final String? renews;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final shape = AppShapes.squircle(AppRadii.lg - 2);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(colors: [c.brandButton, Color.lerp(c.brandButton, Colors.white, 0.18)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        shadows: [BoxShadow(color: c.brandButton.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -12)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(children: [
          Icon(LucideIcons.crown, size: 18, color: c.onButton),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.planPremium, style: t.titleSmall?.copyWith(color: c.onButton, fontWeight: FontWeight.w700)),
              if (renews != null) Text(renews!, style: t.bodySmall?.copyWith(color: c.onButton.withValues(alpha: 0.88))),
            ]),
          ),
          Material(
            color: c.onButton.withValues(alpha: 0.2),
            shape: AppShapes.squircle(AppRadii.pill),
            child: InkWell(
              customBorder: AppShapes.squircle(AppRadii.pill),
              onTap: onManage,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(widthFactor: 1, child: Text(l.manage, style: t.labelMedium?.copyWith(color: c.onButton, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Free: what Premium gives + "Try Premium · ₹1 for 3 months" in amber (screen 24, FR-P9).
class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.onTry});

  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: ShapeDecoration(
        color: c.premiumTint,
        shape: AppShapes.squircle(AppRadii.lg - 2, side: BorderSide(color: c.premium.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(LucideIcons.crown, size: 18, color: c.premium),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.planFree, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(l.planFreeSub, style: t.bodySmall?.copyWith(color: c.premium)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        AppButton(label: l.premiumTryButton, kind: AppButtonKind.premium, height: 44, onPressed: onTry),
      ]),
    );
  }
}
