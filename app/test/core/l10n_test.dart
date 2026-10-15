import 'package:cashflow/core/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hi = lookupAppLocalizations(const Locale('hi'));
  final gu = lookupAppLocalizations(const Locale('gu'));

  test('three launch languages are supported', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), {'en', 'hi', 'gu'});
    expect(supportedAppLocales.length, 3);
  });

  test('key terms use the agreed words (brief T03)', () {
    expect(hi.udhar, 'उधार');
    expect(gu.udhar, 'ઉધાર');
    for (final l in [en, hi, gu]) {
      expect(l.navEmi, 'EMI'); // EMI stays in Latin script
      expect(l.appName, 'CashFlow');
    }
  });

  test('plurals and placeholders', () {
    expect(en.dueInDays(0), 'Due today');
    expect(en.dueInDays(1), 'Due tomorrow');
    expect(en.dueInDays(5), 'Due in 5 days');
    expect(en.pinWrong(1), 'Wrong PIN. 1 try left');
    expect(en.pinWrong(3), 'Wrong PIN. 3 tries left');
    expect(en.owesYou('Rahul'), 'Rahul owes you');
    expect(hi.dueInDays(5), '5 दिन में ड्यू');
    expect(gu.monthsCount(12), '12 મહિના');
    expect(en.installmentOf(5, 12, '5 Nov'), 'Installment 5 of 12 · due 5 Nov');
  });
}
