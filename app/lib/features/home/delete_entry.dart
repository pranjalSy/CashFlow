import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../data/local/database.dart';
import '../../data/repositories/entry_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';

/// "Delete this entry?" (E4): confirm sheet, soft delete, then 5 s Undo.
Future<bool> confirmAndDeleteEntry(BuildContext context, WidgetRef ref, HomeEntry entry, Category? category) async {
  final l = context.l10n;
  final ok = await showAppSheet<bool>(
    context,
    builder: (context) {
      final c = context.colors;
      final t = Theme.of(context).textTheme;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        IconTile(icon: LucideIcons.trash2, color: c.expense, tint: c.expenseTint, size: 56),
        const SizedBox(height: AppSpacing.sm),
        Text(l.deleteEntryTitle, textAlign: TextAlign.center, style: t.titleLarge),
        const SizedBox(height: 6),
        Text(l.deleteEntryBody, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: AppButton(label: l.cancel, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context, false))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppButton(label: l.delete, kind: AppButtonKind.danger, onPressed: () => Navigator.pop(context, true))),
        ]),
      ]);
    },
  );
  if (ok != true || !context.mounted) return false;
  final repo = ref.read(entryRepositoryProvider);
  final batch = await repo.delete(entry.id);
  if (!context.mounted) return true;
  final title = entry.title ?? (category == null ? l.catOthers : categoryName(l, category));
  CompactSnackbar.show(context, message: l.entryDeleted(title), actionLabel: l.undo, onAction: () => repo.undoDelete(entry.id, batch));
  return true;
}
