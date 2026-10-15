import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/amount_field.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return OnboardingScaffold(
      step: 2,
      scroll: false,
      onBack: () => context.go('/fingerprint'),
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxHeight < 640;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.openingTitle, style: t.headlineSmall),
                      const SizedBox(height: 6),
                      Text(l.openingBody, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      AmountField(
                        label: l.openingCash,
                        typed: _cash,
                        active: _active == 0,
                        icon: Icons.payments_rounded,
                        onTap: () => setState(() => _active = 0),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AmountField(
                        label: l.openingOnline,
                        typed: _online,
                        active: _active == 1,
                        icon: Icons.account_balance_rounded,
                        onTap: () => setState(() => _active = 1),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text(l.openingTotal, style: t.labelMedium),
                          const Spacer(),
                          AmountText(Money.format(_cashPaise + _onlinePaise), size: 18, color: c.text),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: ShapeDecoration(color: c.sheet, shape: AppShapes.squircle(AppRadii.xl)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: NumberPad(onDigit: _press, onBackspace: _back, keyHeight: compact ? 44 : 50),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: l.continueLabel, onPressed: () => _save(skip: false)),
              TextButton(onPressed: () => _save(skip: true), child: Text(l.skipForNow)),
            ],
          );
        },
      ),
    );
  }
}
