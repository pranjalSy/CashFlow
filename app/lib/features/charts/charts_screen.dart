import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/tab_page.dart';

/// Charts & budget arrive in T12; the tab already exists so the bottom bar matches the design.
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TabPage(
      title: l.navCharts,
      children: [
        AppCard(child: EmptyState(icon: LucideIcons.chartPie, title: l.navCharts, message: l.chartsComingSoon)),
      ],
    );
  }
}
