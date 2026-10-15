import 'dart:math' as math;

import 'dates.dart';

/// EMI maths, reducing balance (PRD §8, TRD 7). All money in paise, rates in basis points.
abstract final class Emi {
  static const maxMonths = 600;

  static double _monthlyRate(int rateBp) => rateBp / 10000 / 12;

  /// Monthly EMI for a loan, rounded once to whole paise. Zero rate: loan ÷ months.
  static int amount({required int principal, required int rateBp, required int months}) {
    if (principal <= 0 || months <= 0) throw ArgumentError('principal and months must be positive');
    if (rateBp == 0) return (principal / months).round();
    final r = _monthlyRate(rateBp);
    final f = math.pow(1 + r, months);
    return (principal * r * f / (f - 1)).round();
  }

  /// How many months a chosen EMI takes; null when it can never pay the loan off
  /// (EMI not more than the first month's interest, or more than 600 months).
  static int? monthsFor({required int principal, required int rateBp, required int emi}) {
    if (principal <= 0 || emi <= 0) return null;
    if (rateBp == 0) return (principal / emi).ceil();
    final r = _monthlyRate(rateBp);
    if (emi <= principal * r) return null;
    final n = (-math.log(1 - principal * r / emi) / math.log(1 + r)).ceil();
    return n > maxMonths ? null : n;
  }

  /// Monthly interest on the full loan (shown in the "Not possible" message).
  static int firstMonthInterest({required int principal, required int rateBp}) =>
      (principal * _monthlyRate(rateBp)).round();

  /// All installments. Interest is rounded each month; the last installment takes the
  /// remainder so the total repaid matches exactly (FR-E4). Dates clamp 29/30/31.
  static List<Installment> schedule({
    required int principal,
    required int rateBp,
    required int emi,
    required int months,
    required LocalDate firstDue,
  }) {
    final r = _monthlyRate(rateBp);
    var balance = principal;
    final list = <Installment>[];
    for (var i = 0; i < months; i++) {
      final interest = (balance * r).round();
      final last = i == months - 1;
      final principalPart = last ? balance : math.min(emi - interest, balance);
      final amount = principalPart + interest;
      balance -= principalPart;
      list.add(Installment(
        seq: i + 1,
        dueDate: firstDue.addMonths(i, preferredDay: firstDue.day),
        amount: amount,
        interest: interest,
        principal: principalPart,
      ));
      if (balance <= 0) break;
    }
    return list;
  }
}

class Installment {
  const Installment({required this.seq, required this.dueDate, required this.amount, required this.interest, required this.principal});

  final int seq;
  final LocalDate dueDate;
  final int amount;
  final int interest;
  final int principal;
}
