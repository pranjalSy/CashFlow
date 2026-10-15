import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../core/theme/app_colors.dart';
import '../shared/widgets/app_page.dart';
import '../shared/widgets/glass_nav_bar.dart';
import '../shared/widgets/plus_menu.dart';

/// Four tabs in a glass pill + "+" menu (D1, D3). On the EMI & Bills tab "+" offers only
/// Add EMI and Add bill (I2).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _menu = false;

  void _go(String location) {
    setState(() => _menu = false);
    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final emiTab = widget.shell.currentIndex == 3;
    final items = emiTab
        ? [
            PlusMenuItem(label: l.addEmi, icon: Icons.two_wheeler_rounded, color: c.lent, tint: c.lentTint, onTap: () => _go('/emi/new')),
            PlusMenuItem(label: l.addBill, icon: Icons.bolt_rounded, color: c.dueSoon, tint: c.dueSoonTint, onTap: () => _go('/bills/new')),
          ]
        : [
            PlusMenuItem(label: l.expense, icon: Icons.north_east_rounded, color: c.expense, tint: c.expenseTint, onTap: () => _go('/entry/new?kind=expense')),
            PlusMenuItem(label: l.income, icon: Icons.south_west_rounded, color: c.income, tint: c.incomeTint, onTap: () => _go('/entry/new?kind=income')),
            PlusMenuItem(label: l.lent, icon: Icons.east_rounded, color: c.lent, tint: c.lentTint, onTap: () => _go('/udhar/new?direction=lent')),
            PlusMenuItem(label: l.borrowed, icon: Icons.west_rounded, color: c.borrowed, tint: c.borrowedTint, onTap: () => _go('/udhar/new?direction=borrowed')),
          ];
    return PopScope(
      canPop: !_menu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menu) setState(() => _menu = false);
      },
      child: AppPage(
        bottomNavigationBar: GlassNavBar(
          index: widget.shell.currentIndex,
          onTap: (i) {
            setState(() => _menu = false);
            widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
          },
          onPlus: () => setState(() => _menu = !_menu),
          plusOpen: _menu,
          plusLabel: l.add,
          items: [
            NavItem(icon: Icons.home_rounded, label: l.navHome),
            NavItem(icon: Icons.people_alt_rounded, label: l.navContacts),
            NavItem(icon: Icons.pie_chart_rounded, label: l.navCharts),
            NavItem(icon: Icons.calendar_month_rounded, label: l.navEmi),
          ],
        ),
        floating: PlusMenu(open: _menu, items: items, onClose: () => setState(() => _menu = false)),
        child: widget.shell,
      ),
    );
  }
}
