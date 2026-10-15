import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 4-digit PIN stored only as a salted slow hash in secure storage (FR-L2, TRD 11.2).
/// Wrong attempts: 5 tries, then 30 s lock, doubling each time; survives restarts (FR-L7).
class PinService {
  PinService({FlutterSecureStorage? storage, DateTime Function()? clock, this.iterations = 100000, this.offThread = true})
      : _storage = storage ?? const FlutterSecureStorage(),
        _clock = clock ?? DateTime.now;

  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;
  /// PBKDF2-HMAC-SHA256 rounds for new PINs (old PINs keep their stored count).
  final int iterations;

  /// Hash in a background isolate (off in widget tests, which run on a fake clock).
  final bool offThread;

  static const _hashKey = 'pin.hash';
  static const _saltKey = 'pin.salt';
  static const _iterKey = 'pin.iterations';
  static const _failsKey = 'pin.failed';
  static const _lockedUntilKey = 'pin.locked_until';
  static const _lockStepKey = 'pin.lock_step';

  static const maxTries = 5;
  static const firstLock = Duration(seconds: 30);

  static bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<bool> hasPin() async => (await _storage.read(key: _hashKey)) != null;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be 4 digits');
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _hashKey, value: base64Encode(hash));
    await _storage.write(key: _iterKey, value: '$iterations');
    await _resetAttempts();
  }

  /// Remaining lock time, or null when the user may try.
  Future<Duration?> lockedFor() async {
    final until = int.tryParse(await _storage.read(key: _lockedUntilKey) ?? '');
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until, isUtc: true).difference(_clock().toUtc());
    return left.isNegative || left == Duration.zero ? null : left;
  }

  /// Checks a PIN. Returns the outcome with tries left or lock time.
  Future<PinResult> verify(String pin) async {
    final locked = await lockedFor();
    if (locked != null) return PinResult.locked(locked);
    final hash = await _storage.read(key: _hashKey);
    final salt = await _storage.read(key: _saltKey);
    if (hash == null || salt == null) return const PinResult.noPin();
    final rounds = int.tryParse(await _storage.read(key: _iterKey) ?? '') ?? iterations;
    final candidate = await _derive(pin, base64Decode(salt), rounds);
    if (_equal(candidate, base64Decode(hash))) {
      await _resetAttempts();
      return const PinResult.ok();
    }
    final fails = (int.tryParse(await _storage.read(key: _failsKey) ?? '') ?? 0) + 1;
    if (fails >= maxTries) {
      final step = int.tryParse(await _storage.read(key: _lockStepKey) ?? '') ?? 0;
      final lock = firstLock * (1 << step);
      await _storage.write(key: _lockedUntilKey, value: '${_clock().toUtc().add(lock).millisecondsSinceEpoch}');
      await _storage.write(key: _lockStepKey, value: '${step + 1}');
      await _storage.write(key: _failsKey, value: '0');
      return PinResult.locked(lock);
    }
    await _storage.write(key: _failsKey, value: '$fails');
    return PinResult.wrong(maxTries - fails);
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _failsKey);
    await _storage.delete(key: _lockedUntilKey);
    await _storage.delete(key: _lockStepKey);
  }

  /// Runs off the UI thread so the PIN screen never stutters while hashing.
  Future<List<int>> _derive(String pin, List<int> salt, int iterations) {
    Future<List<int>> run() async {
      final algo = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
      final key = await algo.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
      return key.extractBytes();
    }

    return offThread ? Isolate.run(run) : run();
  }

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

enum PinOutcome { ok, wrong, locked, noPin }

class PinResult {
  const PinResult._(this.outcome, {this.triesLeft, this.lockedFor});

  const PinResult.ok() : this._(PinOutcome.ok);
  const PinResult.noPin() : this._(PinOutcome.noPin);
  const PinResult.wrong(int triesLeft) : this._(PinOutcome.wrong, triesLeft: triesLeft);
  const PinResult.locked(Duration lockedFor) : this._(PinOutcome.locked, lockedFor: lockedFor);

  final PinOutcome outcome;
  final int? triesLeft;
  final Duration? lockedFor;
}
