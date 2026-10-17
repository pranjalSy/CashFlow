import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Small phone actions for Settings, through the app's own Android channel (MainActivity):
/// the app version, this app's system settings page (battery / auto-start help, FR-R5), and links.
class SystemService {
  const SystemService();

  static const _channel = MethodChannel('cashflow/system');

  Future<String> appVersion() async => await _channel.invokeMethod<String>('appVersion') ?? '';

  Future<void> openAppSettings() => _channel.invokeMethod('openAppSettings');

  Future<void> openUrl(String url) => _channel.invokeMethod('openUrl', {'url': url});
}

final systemServiceProvider = Provider<SystemService>((ref) => const SystemService());

final appVersionProvider = FutureProvider<String>((ref) => ref.watch(systemServiceProvider).appVersion());
