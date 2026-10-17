import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/states.dart';

/// What a Free user sees in place of EMIs (screen 17, like Charts): locked card + Try Premium.
class EmiLockCard extends StatelessWidget {
  const EmiLockCard({super.key, this.title, this.message});

  /// Defaults to the EMI & bills wording.
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PremiumLockCard(
      title: title ?? l.emiLockTitle,
      message: message ?? l.emiLockBody,
      buttonLabel: l.premiumTryButton,
      fineprint: l.premiumFineprint,
      onTry: () => CompactSnackbar.show(context, message: l.premiumComingLater),
    );
  }
}
