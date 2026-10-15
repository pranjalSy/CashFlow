import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum FingerprintState {
  /// No usable sensor: the fingerprint screen is skipped (C5).
  unavailable,

  /// Sensor present but no finger enrolled: "Set up fingerprint first".
  notEnrolled,

  /// A strong biometric (fingerprint) is enrolled and can be used.
  ready,
}

/// Fingerprint unlock only, strong biometrics only (DESIGN_DECISIONS C5, TRD 11.3).
/// The app never sees biometric data, only success or failure.
class BiometricService {
  BiometricService({LocalAuthentication? auth, FlutterSecureStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _enabledKey = 'fingerprint.enabled';

  Future<FingerprintState> state() async {
    try {
      if (!await _auth.canCheckBiometrics) return FingerprintState.unavailable;
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return FingerprintState.notEnrolled;
      // Android often reports only a class (strong/weak). Strong-class sensors on these
      // phones are fingerprint; weak face unlock is never accepted.
      final usable = enrolled.contains(BiometricType.fingerprint) || enrolled.contains(BiometricType.strong);
      return usable ? FingerprintState.ready : FingerprintState.notEnrolled;
    } on PlatformException {
      return FingerprintState.unavailable;
    } on LocalAuthException {
      return FingerprintState.unavailable;
    }
  }

  Future<bool> isEnabled() async => (await _storage.read(key: _enabledKey)) == 'true';

  Future<void> setEnabled(bool value) => value ? _storage.write(key: _enabledKey, value: 'true') : _storage.delete(key: _enabledKey);

  /// System fingerprint prompt. Returns false on cancel, failure or lockout.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
