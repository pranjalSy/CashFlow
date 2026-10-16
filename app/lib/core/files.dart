import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saves export files to Downloads and opens or shares them (FR-C2), through the app's own Android
/// channel (MainActivity). The file never leaves the phone unless the user shares it.
class FileService {
  const FileService();

  static const _channel = MethodChannel('cashflow/files');

  /// Returns the saved file's content URI.
  Future<String> saveToDownloads(String name, String mime, Uint8List bytes) async =>
      (await _channel.invokeMethod<String>('saveToDownloads', {'name': name, 'mime': mime, 'bytes': bytes}))!;

  Future<void> open(String uri, String mime) => _channel.invokeMethod('open', {'uri': uri, 'mime': mime});

  Future<void> share(String uri, String mime) => _channel.invokeMethod('share', {'uri': uri, 'mime': mime});
}

final fileServiceProvider = Provider<FileService>((ref) => const FileService());
