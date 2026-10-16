import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/states.dart';

/// What a Free user sees in place of EMIs (screen 17, like Charts): locked card + Try Premium.
class EmiLockCard extends StatelessWidget {
  const EmiLockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PremiumLockCard(
      title: l.emiLockTitle,
      message: l.emiLockBody,
      buttonLabel: l.premiumTryButton,
      fineprint: l.premiumFineprint,
      onTry: () => CompactSnackbar.show(context, message: l.premiumComingLater),
    );
  }
}
