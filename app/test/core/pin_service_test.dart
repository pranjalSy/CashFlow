import 'package:cashflow/core/security/pin_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime.utc(2026, 10, 16, 8);
  PinService service() => PinService(clock: () => now, iterations: 2000);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 16, 8);
  });

  test('stores only a salted hash, never the PIN', () async {
    final s = service();
    expect(await s.hasPin(), isFalse);
    await s.setPin('4829');
    final all = await const FlutterSecureStorage().readAll();
    expect(all.values.any((v) => v.contains('4829')), isFalse);
    expect(all.keys, containsAll(['pin.hash', 'pin.salt']));
    expect(await s.hasPin(), isTrue);
  });

  test('right PIN unlocks, wrong PIN counts down', () async {
    final s = service();
    await s.setPin('4829');
    expect((await s.verify('4829')).outcome, PinOutcome.ok);
    final r = await s.verify('1111');
    expect(r.outcome, PinOutcome.wrong);
    expect(r.triesLeft, 4);
  });

  test('5 wrong tries lock for 30 s, then 60 s, and survive a restart', () async {
    final s = service();
    await s.setPin('4829');
    PinResult r = const PinResult.noPin();
    for (var i = 0; i < 5; i++) {
      r = await s.verify('0000');
    }
    expect(r.outcome, PinOutcome.locked);
    expect(r.lockedFor, const Duration(seconds: 30));
    // Restart: a new service instance reads the same storage.
    final restarted = service();
    expect((await restarted.verify('4829')).outcome, PinOutcome.locked);
    now = now.add(const Duration(seconds: 31));
    for (var i = 0; i < 5; i++) {
      r = await restarted.verify('0000');
    }
    expect(r.lockedFor, const Duration(seconds: 60));
    now = now.add(const Duration(seconds: 61));
    expect((await restarted.verify('4829')).outcome, PinOutcome.ok);
  });

  test('salts differ, so the same PIN gives different hashes', () async {
    await service().setPin('1234');
    final h1 = await const FlutterSecureStorage().read(key: 'pin.hash');
    await service().setPin('1234');
    final h2 = await const FlutterSecureStorage().read(key: 'pin.hash');
    expect(h1, isNot(h2));
  });

  test('only 4 digits are accepted', () {
    expect(PinService.isValidPin('1234'), isTrue);
    expect(PinService.isValidPin('123'), isFalse);
    expect(PinService.isValidPin('12a4'), isFalse);
  });
}
