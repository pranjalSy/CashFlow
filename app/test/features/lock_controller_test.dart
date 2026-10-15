import 'package:cashflow/features/lock/lock_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime.utc(2026, 10, 16, 9);
  LockController make() => LockController(clock: () => now);

  test('locks again after 1 minute in the background (default)', () {
    final c = make();
    var asked = 0;
    c.onLockNeeded = () => asked++;
    c.markUnlocked();
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 59));
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(asked, 0);
    expect(c.isUnlocked, isTrue);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(asked, 1);
    expect(c.isUnlocked, isFalse);
  });

  test('"Immediately" locks on every return', () {
    final c = make()..lockAfter = Duration.zero;
    var asked = 0;
    c.onLockNeeded = () => asked++;
    c.markUnlocked();
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(asked, 1);
  });

  test('never asks while still locked (first run / lock screen showing)', () {
    final c = make();
    var asked = 0;
    c.onLockNeeded = () => asked++;
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 10));
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(asked, 0);
  });
}
