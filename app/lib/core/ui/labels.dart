import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local/database.dart';
import '../l10n.dart';
import '../utils/dates.dart';

/// Icon for a category icon key (stored as text so it syncs).
IconData categoryIcon(String key) => switch (key) {
      'food' => Icons.restaurant_rounded,
      'groceries' => Icons.shopping_cart_rounded,
      'travel' => Icons.directions_bus_rounded,
      'fuel' => Icons.local_gas_station_rounded,
      'shopping' => Icons.shopping_bag_rounded,
      'bills' => Icons.bolt_rounded,
      'rent' => Icons.house_rounded,
      'health' => Icons.favorite_rounded,
      'education' => Icons.menu_book_rounded,
      'fun' => Icons.movie_rounded,
      'recharge' => Icons.smartphone_rounded,
      'gifts' => Icons.card_giftcard_rounded,
      'personal' => Icons.auto_awesome_rounded,
      'emi' => Icons.event_repeat_rounded,
      'salary' => Icons.work_rounded,
      'business' => Icons.storefront_rounded,
      'freelance' => Icons.laptop_mac_rounded,
      'interest' => Icons.savings_rounded,
      'refund' => Icons.replay_rounded,
      'others' => Icons.more_horiz_rounded,
      _ => Icons.label_rounded,
    };

/// Icons offered for an EMI (FR-E1), stored as their key.
const emiIconKeys = ['bike', 'car', 'phone', 'home', 'laptop', 'tv', 'other'];

IconData emiIcon(String key) => switch (key) {
      'bike' => Icons.two_wheeler_rounded,
      'car' => Icons.directions_car_rounded,
      'phone' => Icons.smartphone_rounded,
      'home' => Icons.home_rounded,
      'laptop' => Icons.laptop_rounded,
      'tv' => Icons.tv_rounded,
      _ => Icons.account_balance_rounded,
    };

/// Yearly rate in basis points as text ("12", "10.5").
String rateText(int rateBp) {
  final whole = rateBp ~/ 100;
  final frac = rateBp % 100;
  if (frac == 0) return '$whole';
  return '$whole.${frac.toString().padLeft(2, '0').replaceAll(RegExp(r'0$'), '')}';
}

/// Localized name of a default category, or the user's own name.
String categoryName(AppLocalizations l, Category c) => switch (c.nameKey) {
      'catFood' => l.catFood,
      'catGroceries' => l.catGroceries,
      'catTravel' => l.catTravel,
      'catFuel' => l.catFuel,
      'catShopping' => l.catShopping,
      'catBills' => l.catBills,
      'catRent' => l.catRent,
      'catHealth' => l.catHealth,
      'catEducation' => l.catEducation,
      'catFun' => l.catFun,
      'catRecharge' => l.catRecharge,
      'catGifts' => l.catGifts,
      'catPersonal' => l.catPersonal,
      'catEmi' => l.catEmi,
      'catOthers' => l.catOthers,
      'catSalary' => l.catSalary,
      'catBusiness' => l.catBusiness,
      'catFreelance' => l.catFreelance,
      'catInterest' => l.catInterest,
      'catGift' => l.catGift,
      'catRefund' => l.catRefund,
      _ => c.name,
    };

/// Category colour, softened into a tint for icon boxes in both themes.
Color categoryTint(Color color, Brightness brightness) => color.withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.12);

/// Icon colour readable in both themes (lighter on black).
Color categoryInk(Color color, Brightness brightness) =>
    brightness == Brightness.dark ? Color.lerp(color, Colors.white, 0.35)! : color;

/// "Cash", "UPI", "Card", "Bank" or "Online".
String paymentLabel(AppLocalizations l, String mode, String? method) {
  if (mode == 'cash') return l.cash;
  return switch (method) {
    'upi' => l.upi,
    'card' => l.card,
    'bank' => l.bank,
    _ => l.online,
  };
}

/// "Today · 13 Oct", "Yesterday · 12 Oct" or "Mon, 6 Oct".
String dayLabel(BuildContext context, LocalDate day, {LocalDate? today}) {
  final l = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = today ?? Ist.today();
  final date = DateTime.utc(day.year, day.month, day.day);
  final short = DateFormat('d MMM', locale).format(date);
  if (day == now) return '${l.today} · $short';
  if (day == now.addDays(-1)) return '${l.yesterday} · $short';
  return DateFormat('EEE, d MMM', locale).format(date);
}

/// "October" / "Oct 2026" style month labels.
String monthName(BuildContext context, int year, int month) =>
    DateFormat('MMMM', Localizations.localeOf(context).toLanguageTag()).format(DateTime.utc(year, month));

String monthShort(BuildContext context, int year, int month) =>
    DateFormat('MMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(DateTime.utc(year, month));

String shortDate(BuildContext context, LocalDate d) =>
    DateFormat('d MMM', Localizations.localeOf(context).toLanguageTag()).format(DateTime.utc(d.year, d.month, d.day));

String longDate(BuildContext context, LocalDate d) =>
    DateFormat('d MMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(DateTime.utc(d.year, d.month, d.day));

/// India wall-clock time of an instant ("6:40 PM").
String timeLabel(BuildContext context, DateTime instant) {
  final w = Ist.wall(instant);
  return DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(DateTime.utc(2000, 1, 1, w.hour, w.minute));
}
