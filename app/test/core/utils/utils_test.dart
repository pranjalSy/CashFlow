import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/core/utils/emi.dart';
import 'package:cashflow/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format (Indian grouping, ₹)', () {
    test('whole rupees', () {
      expect(Money.format(12000000), '₹1,20,000');
      expect(Money.format(450000), '₹4,500');
      expect(Money.format(0), '₹0');
      expect(Money.format(1000000000), '₹1,00,00,000');
    });
    test('paise shown only when present', () {
      expect(Money.format(799639), '₹7,996.39');
      expect(Money.format(245050), '₹2,450.50');
    });
    test('signs', () {
      expect(Money.format(-245000), '−₹2,450');
      expect(Money.format(4500000, showPlus: true), '+₹45,000');
    });
  });

  group('Money.parse and typing', () {
    test('parse to paise', () {
      expect(Money.parse('2450'), 245000);
      expect(Money.parse('2450.5'), 245050);
      expect(Money.parse('0.05'), 5);
      expect(Money.parse(''), isNull);
      expect(Money.parse('.'), isNull);
      expect(Money.parse('1.234'), isNull);
    });
    test('number pad rules', () {
      var t = '';
      for (final k in ['0', '2', '4', '.', '5', '0', '9']) {
        t = AmountTyping.press(t, k);
      }
      expect(t, '24.50');
      expect(AmountTyping.press('5.', '.'), '5.');
      expect(AmountTyping.press('', '.'), '0.');
      expect(AmountTyping.press('123456789', '1'), '123456789');
      expect(AmountTyping.backspace('24.5'), '24.');
      expect(Money.formatTyping('120000.5'), '1,20,000.5');
      expect(Money.formatTyping(''), '0');
    });
    test('editing an existing amount', () {
      expect(AmountTyping.fromPaise(245000), '2450');
      expect(AmountTyping.fromPaise(245050), '2450.5');
      expect(AmountTyping.fromPaise(245005), '2450.05');
    });
  });

  group('Ist / LocalDate', () {
    test('India date crosses midnight 5:30 hours before UTC', () {
      expect(Ist.dateOf(DateTime.utc(2026, 10, 13, 18, 29)), const LocalDate(2026, 10, 13));
      expect(Ist.dateOf(DateTime.utc(2026, 10, 13, 18, 30)), const LocalDate(2026, 10, 14));
    });
    test('month range is IST midnight to IST midnight', () {
      final (start, end) = Ist.monthRange(2026, 10);
      expect(start, DateTime.utc(2026, 9, 30, 18, 30));
      expect(end, DateTime.utc(2026, 10, 31, 18, 30));
      final (decStart, decEnd) = Ist.monthRange(2026, 12);
      expect(decStart, DateTime.utc(2026, 11, 30, 18, 30));
      expect(decEnd, DateTime.utc(2026, 12, 31, 18, 30));
    });
    test('29/30/31 clamp to the last day of short months (FR-E4)', () {
      const jan31 = LocalDate(2027, 1, 31);
      expect(jan31.addMonths(1), const LocalDate(2027, 2, 28));
      expect(jan31.addMonths(1, preferredDay: 31).addMonths(1, preferredDay: 31), const LocalDate(2027, 3, 31));
      expect(const LocalDate(2028, 1, 30).addMonths(1), const LocalDate(2028, 2, 29));
      expect(const LocalDate(2026, 11, 15).addMonths(2), const LocalDate(2027, 1, 15));
    });
    test('ISO round trip and day counts', () {
      expect(LocalDate.parse('2026-11-05').toIso(), '2026-11-05');
      expect(const LocalDate(2026, 10, 14).daysUntil(const LocalDate(2026, 11, 5)), 22);
    });
  });

  group('EMI (reference numbers, PRD §8)', () {
    const loan = 9000000; // ₹90,000
    const rate = 1200; // 12%

    test('₹90,000 at 12% for 12 months = ₹7,996.39', () {
      expect(Emi.amount(principal: loan, rateBp: rate, months: 12), 799639);
    });

    test('schedule totals are exact; last installment absorbs rounding', () {
      final s = Emi.schedule(principal: loan, rateBp: rate, emi: 799639, months: 12, firstDue: const LocalDate(2026, 7, 5));
      expect(s.length, 12);
      expect(s.fold<int>(0, (a, i) => a + i.principal), loan);
      final total = s.fold<int>(0, (a, i) => a + i.amount);
      expect(total - loan, 595669); // total interest ₹5,956.69
      expect(s.last.amount, 799640); // ₹7,996.40
      expect(s.first.interest, 90000);
      expect(s[4].interest, 61186); // installment 5 interest ₹611.86 (screen 19)
      final remainingAfter4 = s.skip(4).fold<int>(0, (a, i) => a + i.amount);
      expect(remainingAfter4, 6397113); // ₹63,971.13
      expect(s.last.dueDate, const LocalDate(2027, 6, 5));
    });

    test('EMI ₹8,500 takes 12 months with a smaller last installment', () {
      final n = Emi.monthsFor(principal: loan, rateBp: rate, emi: 850000);
      expect(n, 12);
      final s = Emi.schedule(principal: loan, rateBp: rate, emi: 850000, months: n!, firstDue: const LocalDate(2026, 7, 5));
      expect(s.last.amount, closeTo(211298, 1)); // ₹2,112.98 (±1 paisa from monthly rounding)
      expect(s.fold<int>(0, (a, i) => a + i.principal), loan);
    });

    test('EMI not above monthly interest is not possible', () {
      expect(Emi.monthsFor(principal: loan, rateBp: rate, emi: 80000), isNull); // ₹800
      expect(Emi.firstMonthInterest(principal: loan, rateBp: rate), 90000); // ₹900
    });

    test('zero interest: loan ÷ months, exact total', () {
      expect(Emi.amount(principal: 2939400, rateBp: 0, months: 6), 489900); // ₹4,899
      final s = Emi.schedule(principal: 1000000, rateBp: 0, emi: Emi.amount(principal: 1000000, rateBp: 0, months: 3), months: 3, firstDue: const LocalDate(2026, 1, 31));
      expect(s.fold<int>(0, (a, i) => a + i.amount), 1000000);
      expect(s[1].dueDate, const LocalDate(2026, 2, 28));
      expect(s[2].dueDate, const LocalDate(2026, 3, 31));
    });
  });
}
