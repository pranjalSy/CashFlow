import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services.dart';
import '../../data/providers.dart';

/// Changes saved on the phone and not yet uploaded (Settings › Sync). Counted per row, so editing
/// one entry twice is one change. Uploading starts with the sync engine (T17).
final pendingChangesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT COUNT(DISTINCT entity_table || row_id) AS n FROM sync_outbox', readsFrom: {db.syncOutbox})
      .watchSingle()
      .map((r) => r.read<int>('n'));
});

/// Whether fingerprint unlock is on (App lock row and sheet).
final fingerprintOnProvider = FutureProvider<bool>((ref) => ref.watch(biometricServiceProvider).isEnabled());
