import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../data/local/database.dart';
import '../../data/repositories/category_repository.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';

/// Category picker sheet (F5, screen 12): recent 4, search, 4-column grid, "Create".
Future<Category?> pickCategory(BuildContext context, {required String kind, String? selectedId}) {
  return showAppSheet<Category>(context, builder: (context) => _CategoryPicker(kind: kind, selectedId: selectedId));
}

class _CategoryPicker extends ConsumerStatefulWidget {
  const _CategoryPicker({required this.kind, this.selectedId});

  final String kind;
  final String? selectedId;

  @override
  ConsumerState<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<_CategoryPicker> {
  String _query = '';
  List<Category> _recent = const [];

  @override
  void initState() {
    super.initState();
    ref.read(categoryRepositoryProvider).recent(widget.kind).then((r) {
      if (mounted) setState(() => _recent = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final repo = ref.watch(categoryRepositoryProvider);
    final expense = widget.kind == 'expense';
    return StreamBuilder<List<Category>>(
      stream: repo.watchKind(widget.kind),
      builder: (context, snap) {
        final all = snap.data ?? const <Category>[];
        final q = _query.trim().toLowerCase();
        final matches = q.isEmpty ? all : all.where((x) => categoryName(l, x).toLowerCase().contains(q) || x.name.toLowerCase().contains(q)).toList();
        final exact = all.any((x) => categoryName(l, x).toLowerCase() == q);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(expense ? l.categoryExpenseTitle : l.categoryIncomeTitle, style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l.categorySearch,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: c.raised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                if (q.isNotEmpty && !exact)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Material(
                      color: c.raised,
                      shape: AppShapes.squircle(AppRadii.md),
                      child: ListRowTile(
                        leading: IconTile(icon: Icons.add_rounded, color: c.brandText, tint: c.brandTint, size: 44),
                        title: l.categoryCreate(_query.trim()),
                        subtitle: l.categoryCreateSub,
                        onTap: () async {
                          final created = await repo.create(widget.kind, _query);
                          if (context.mounted) Navigator.pop(context, created);
                        },
                      ),
                    ),
                  ),
                if (q.isEmpty && _recent.isNotEmpty) ...[
                  SectionLabel(l.categoryRecent),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final r in _recent)
                      AppChip(
                        label: categoryName(l, r),
                        selected: r.id == widget.selectedId,
                        selectedColor: expense ? c.expenseButton : c.incomeButton,
                        onTap: () => Navigator.pop(context, r),
                      ),
                  ]),
                ],
                if (q.isEmpty) SectionLabel(l.categoryAll),
                const SizedBox(height: 4),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.82,
                  children: [for (final x in matches) _Cell(category: x, selected: x.id == widget.selectedId)],
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.category, required this.selected});

  final Category category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final b = Theme.of(context).brightness;
    final color = Color(category.color);
    final shape = AppShapes.squircle(AppRadii.md, side: BorderSide(color: selected ? categoryInk(color, b) : Colors.transparent, width: 1.5));
    return Material(
      color: selected ? categoryTint(color, b) : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => Navigator.pop(context, category),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconTile(icon: categoryIcon(category.icon), color: categoryInk(color, b), tint: categoryTint(color, b), size: 46),
            const SizedBox(height: 6),
            Text(
              categoryName(l, category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.text),
            ),
          ]),
        ),
      ),
    );
  }
}
