import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../core/theme/app_colors.dart';
import '../shared/widgets/app_page.dart';
import '../shared/widgets/glass_nav_bar.dart';
import '../shared/widgets/motion.dart';
import '../shared/widgets/overlays.dart';
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
            PlusMenuItem(label: l.addBill, icon: Icons.bolt_outlined, color: c.dueSoon, tint: c.dueSoonTint, onTap: () {
              setState(() => _menu = false);
              CompactSnackbar.show(context, message: l.billsComingSoon); // Add bill arrives in T11
            }),
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
            NavItem(icon: Icons.home_outlined, label: l.navHome),
            NavItem(icon: Icons.people_alt_outlined, label: l.navContacts),
            NavItem(icon: Icons.pie_chart_outline_rounded, label: l.navCharts),
            NavItem(icon: Icons.calendar_month_outlined, label: l.navEmi),
          ],
        ),
        floating: PlusMenu(open: _menu, items: items, onClose: () => setState(() => _menu = false)),
        child: _TabFade(index: widget.shell.currentIndex, child: widget.shell),
      ),
    );
  }
}

/// A new tab fades in and settles from 98.5% size (fade-through); the tabs keep their state.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.medium, value: 1);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !Motion.off(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Motion.enter);
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(a),
      child: ScaleTransition(scale: Tween(begin: 0.985, end: 1.0).animate(a), child: widget.child),
    );
  }
}
