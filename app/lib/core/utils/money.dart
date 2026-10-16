import 'package:intl/intl.dart';

/// Money is always integer paise (AGENTS.md §4). These helpers only format and parse.
abstract final class Money {
  static final _whole = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _paise = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _plainWhole = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);

  /// Typographic minus used before expense amounts.
  static const minus = '−';

  /// ₹1,20,000 (whole rupees) or ₹7,996.39 (when there are paise). Negative values show "−₹".
  /// Rounded to the nearest rupee, for summaries and list cards ("₹63,971 remaining", screen 17).
  static String formatWhole(int paise) => format((paise / 100).round() * 100);

  static String format(int paise, {bool showPlus = false}) {
    final abs = paise.abs();
    final text = abs % 100 == 0 ? _whole.format(abs ~/ 100) : _paise.format(abs / 100);
    if (paise < 0) return '$minus$text';
    if (showPlus && paise > 0) return '+$text';
    return text;
  }

  /// Indian grouping without the ₹ sign, for the amount being typed ("1,20,000.5").
  static String formatTyping(String typed) {
    if (typed.isEmpty) return '0';
    final dot = typed.indexOf('.');
    final whole = dot < 0 ? typed : typed.substring(0, dot);
    final grouped = _plainWhole.format(int.tryParse(whole.isEmpty ? '0' : whole) ?? 0).trim();
    return dot < 0 ? grouped : '$grouped${typed.substring(dot)}';
  }

  /// Parses what the user typed on the number pad ("2450.5") to paise (245050). Null if empty or invalid.
  static int? parse(String typed) {
    final value = typed.trim();
    if (value.isEmpty || value == '.') return null;
    final match = RegExp(r'^(\d+)?(?:\.(\d{0,2}))?$').firstMatch(value);
    if (match == null) return null;
    final rupees = int.parse(match.group(1) ?? '0');
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return rupees * 100 + int.parse(fraction.isEmpty ? '0' : fraction);
  }
}

/// Number-pad typing rules: one dot, at most 2 decimals, at most 9 rupee digits (< ₹100 crore).
abstract final class AmountTyping {
  static const maxRupeeDigits = 9;

  static String press(String current, String key) {
    if (key == '.') {
      if (current.contains('.')) return current;
      return current.isEmpty ? '0.' : '$current.';
    }
    final dot = current.indexOf('.');
    if (dot >= 0) {
      if (current.length - dot - 1 >= 2) return current;
      return current + key;
    }
    if (current == '0') return key;
    if (current.length >= maxRupeeDigits) return current;
    return current + key;
  }

  static String backspace(String current) => current.isEmpty ? '' : current.substring(0, current.length - 1);

  /// Starting text when editing an existing amount.
  static String fromPaise(int paise) {
    if (paise % 100 == 0) return '${paise ~/ 100}';
    final cents = paise % 100;
    return '${paise ~/ 100}.${cents % 10 == 0 ? cents ~/ 10 : cents.toString().padLeft(2, '0')}';
  }
}
