import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';

/// Locks again after the app was in the background longer than "Lock after" (FR-L5, FR-L8).
/// Default 1 minute; Settings › Lock after picks immediately / 1 min / 5 min (saved per phone).
class LockController with WidgetsBindingObserver {
  LockController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  Duration lockAfter = const Duration(minutes: 1);
  DateTime? _backgroundSince;
  bool _unlocked = false;

  /// Called by the router to show the lock screen; set in app.dart.
  void Function()? onLockNeeded;

  bool get isUnlocked => _unlocked;

  void markUnlocked() {
    _unlocked = true;
    _backgroundSince = null;
  }

  void lockNow() => _unlocked = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundSince ??= _clock();
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        _backgroundSince = null;
        if (_unlocked && since != null && shouldLock(since)) {
          _unlocked = false;
          onLockNeeded?.call();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  bool shouldLock(DateTime backgroundSince) => _clock().difference(backgroundSince) >= lockAfter;
}

final lockControllerProvider = Provider<LockController>((ref) {
  final c = LockController()..lockAfter = Duration(seconds: ref.read(uiPrefsProvider).lockAfterSeconds);
  WidgetsBinding.instance.addObserver(c);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(c));
  return c;
});
