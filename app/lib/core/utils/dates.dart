/// Dates for India: instants are stored in UTC, months and "today" use IST (UTC+5:30, no DST).
abstract final class Ist {
  static const offset = Duration(hours: 5, minutes: 30);

  /// Wall-clock time in India for a UTC instant (returned as a UTC-flagged DateTime holding IST fields).
  static DateTime wall(DateTime instant) => instant.toUtc().add(offset);

  /// India date of a UTC instant.
  static LocalDate dateOf(DateTime instant) {
    final w = wall(instant);
    return LocalDate(w.year, w.month, w.day);
  }

  static LocalDate today([DateTime? now]) => dateOf(now ?? DateTime.now());

  /// UTC instant of an India wall time.
  static DateTime instantOf(LocalDate date, {int hour = 0, int minute = 0}) =>
      DateTime.utc(date.year, date.month, date.day, hour, minute).subtract(offset);

  /// [start, end) of an India month as UTC instants (for queries on `occurred_at`).
  static (DateTime, DateTime) monthRange(int year, int month) {
    final start = instantOf(LocalDate(year, month, 1));
    final next = month == 12 ? LocalDate(year + 1, 1, 1) : LocalDate(year, month + 1, 1);
    return (start, instantOf(next));
  }
}

/// A calendar date without time or zone (due dates are stored as ISO `YYYY-MM-DD`).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.parse(String iso) {
    final p = iso.split('-');
    if (p.length != 3) throw FormatException('Not an ISO date', iso);
    return LocalDate(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  final int year;
  final int month;
  final int day;

  static int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  /// Same day N months later; 29/30/31 is clamped to the month's last day (FR-E4).
  LocalDate addMonths(int months, {int? preferredDay}) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final wanted = preferredDay ?? day;
    final last = daysInMonth(y, m);
    return LocalDate(y, m, wanted > last ? last : wanted);
  }

  LocalDate addDays(int days) {
    final d = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(d.year, d.month, d.day);
  }

  int daysUntil(LocalDate other) =>
      DateTime.utc(other.year, other.month, other.day).difference(DateTime.utc(year, month, day)).inDays;

  String toIso() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) =>
      year != other.year ? year - other.year : (month != other.month ? month - other.month : day - other.day);

  @override
  bool operator ==(Object other) => other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
