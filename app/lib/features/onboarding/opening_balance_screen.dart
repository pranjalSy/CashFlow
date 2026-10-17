import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/number_pad.dart';
import 'onboarding_scaffold.dart';

/// Opening balance for cash and online money; may be 0 or skipped (FR-O7, screen 08).
class OpeningBalanceScreen extends ConsumerStatefulWidget {
  const OpeningBalanceScreen({super.key, this.next = '/contacts-permission'});

  final String next;

  @override
  ConsumerState<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends ConsumerState<OpeningBalanceScreen> {
  String _cash = '';
  String _online = '';
  int _active = 0;

  int get _cashPaise => Money.parse(_cash) ?? 0;
  int get _onlinePaise => Money.parse(_online) ?? 0;

  void _press(String key) => setState(() {
    if (_active == 0) {
      _cash = AmountTyping.press(_cash, key);
    } else {
      _online = AmountTyping.press(_online, key);
    }
  });

  void _back() => setState(() {
    if (_active == 0) {
      _cash = AmountTyping.backspace(_cash);
    } else {
      _online = AmountTyping.backspace(_online);
    }
  });

  Future<void> _save({required bool skip}) async {
    final language = ref.read(localeProvider)?.languageCode ?? 'en';
    await ref.read(profileRepositoryProvider).saveOpening(cash: skip ? 0 : _cashPaise, online: skip ? 0 : _onlinePaise, language: language);
    if (mounted) context.go(widget.next);
  }

  bool _padOpen = true;

  /// "Next" on the pad: cash → online → close the pad (screen 08).
  void _next() => setState(() {
        if (_active == 0) {
          _active = 1;
        } else {
          _padOpen = false;
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final total = _cashPaise + _onlinePaise;
    Widget row(int index, IconData icon, Color color, Color tint, String title, String sub, String typed) {
      final on = _padOpen && _active == index;
      return Material(
        color: c.card,
        shape: AppShapes.squircle(AppRadii.lg, side: BorderSide(color: on ? c.brandButton : Colors.transparent, width: 1.5)),
        child: InkWell(
          customBorder: AppShapes.squircle(AppRadii.lg),
          onTap: () => setState(() {
            _active = index;
            _padOpen = true;
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              IconTile(icon: icon, color: color, tint: tint, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(sub, style: t.bodySmall),
                ]),
              ),
              AmountText('₹${Money.formatTyping(typed)}', size: 22, color: typed.isEmpty ? c.textMuted : c.text, alignment: Alignment.centerRight),
            ]),
          ),
        ),
      );
    }

    return OnboardingScaffold(
      step: 2,
      scroll: false,
      onBack: () => context.go('/fingerprint'),
      trailing: TextButton(onPressed: () => _save(skip: true), child: Text(l.skip, style: t.labelLarge?.copyWith(color: c.textSecondary))),
      bottom: _padOpen ? null : AppButton(label: l.continueLabel, onPressed: () => _save(skip: false)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.openingTitle, style: t.headlineSmall),
              const SizedBox(height: 6),
              Text(l.openingBody, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              row(0, LucideIcons.banknote, c.income, c.incomeTint, l.cash, l.cashSub, _cash),
              const SizedBox(height: AppSpacing.xs),
              row(1, LucideIcons.landmark, c.brandText, c.brandTint, l.online, l.onlineSub, _online),
              if (!_padOpen) ...[
                const SizedBox(height: AppSpacing.sm),
                DashedOutline(color: c.border, radius: 0, child: const SizedBox(height: 1, width: double.infinity)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
                  child: Row(children: [
                    Expanded(child: Text(l.totalBalance, style: t.bodyMedium?.copyWith(color: c.textSecondary))),
                    CountUpAmount(paise: total, size: 22, color: c.income, alignment: Alignment.centerRight),
                  ]),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 2, left: 4), child: Icon(LucideIcons.info, size: 14, color: c.textMuted)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l.openingNote, style: t.bodySmall)),
                ]),
              ],
            ]),
          ),
        ),
        if (_padOpen)
          Material(
            color: c.sheet,
            shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Padding(padding: const EdgeInsets.only(left: 6), child: Text(l.totalAmount, style: t.bodySmall)),
                  const SizedBox(width: 8),
                  AmountText(Money.format(total), size: 15),
                  const Spacer(),
                  AppButton(label: l.next, onPressed: _next, expand: false, height: 40),
                ]),
                const SizedBox(height: 8),
                NumberPad(keyHeight: MediaQuery.sizeOf(context).height < 700 ? 42 : 48, onDigit: _press, onBackspace: _back),
              ]),
            ),
          ),
      ]),
    );
  }
}
