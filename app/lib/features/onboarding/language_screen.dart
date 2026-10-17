import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/glass.dart';

class AppLanguage {
  const AppLanguage(this.code, this.english, this.native, this.letter, {this.live = false});

  final String code;
  final String english;
  final String native;
  final String letter;

  /// Only English, Hindi and Gujarati work at launch (C2).
  final bool live;
}

const appLanguages = [
  AppLanguage('en', 'English', 'English', 'A', live: true),
  AppLanguage('hi', 'Hindi', 'हिन्दी', 'अ', live: true),
  AppLanguage('gu', 'Gujarati', 'ગુજરાતી', 'અ', live: true),
  AppLanguage('mr', 'Marathi', 'मराठी', 'म'),
  AppLanguage('bn', 'Bengali', 'বাংলা', 'অ'),
  AppLanguage('ta', 'Tamil', 'தமிழ்', 'அ'),
  AppLanguage('te', 'Telugu', 'తెలుగు', 'అ'),
  AppLanguage('kn', 'Kannada', 'ಕನ್ನಡ', 'ಅ'),
  AppLanguage('ml', 'Malayalam', 'മലയാളം', 'അ'),
  AppLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ', 'ਅ'),
  AppLanguage('or', 'Odia', 'ଓଡ଼ିଆ', 'ଅ'),
  AppLanguage('as', 'Assamese', 'অসমীয়া', 'অ'),
  AppLanguage('ur', 'Urdu', 'اردو', 'ا'),
];

/// Language picker with search (screen 03). Default English; the choice applies at once.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key, this.next = '/pin/create'});

  final String next;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final selected = ref.watch(localeProvider)?.languageCode ?? 'en';
    final q = _query.trim().toLowerCase();
    final list = appLanguages
        .where((a) => q.isEmpty || a.english.toLowerCase().contains(q) || a.native.contains(_query.trim()) || a.code == q)
        .toList();
    return AppPage(
      bottomNavigationBar: GlassSurface(
        alwaysGlass: true,
        fill: c.navGlass,
        edge: c.navGlassEdge,
        solid: c.sheet,
        shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: l.continueLabel,
                  onPressed: () async {
                    if (ref.read(localeProvider) == null) await ref.read(localeProvider.notifier).set('en');
                    if (context.mounted) context.go(widget.next);
                  },
                ),
                const SizedBox(height: 6),
                Text(l.languageLater, style: t.bodySmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.languageTitle, style: t.displaySmall?.copyWith(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(l.languageSubtitle, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l.languageSearch,
                  prefixIcon: const Icon(LucideIcons.search),
                  filled: true,
                  fillColor: c.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 140),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _LanguageRow(
                  language: list[i],
                  selected: list[i].code == selected,
                  comingSoon: l.comingSoon,
                  onTap: list[i].live ? () => ref.read(localeProvider.notifier).set(list[i].code) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.selected, required this.comingSoon, this.onTap});

  final AppLanguage language;
  final bool selected;
  final String comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final live = onTap != null;
    final shape = AppShapes.squircle(
      AppRadii.md,
      side: BorderSide(color: selected ? c.brandButton : c.border, width: selected ? 2 : 1),
    );
    return Opacity(
      opacity: live ? 1 : 0.55,
      child: Material(
        color: selected ? c.brandTint : c.card,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: selected ? c.brandButton : c.brandTint, shape: AppShapes.squircle(13)),
                    child: Center(
                      child: Text(language.letter, style: t.titleMedium?.copyWith(color: selected ? c.onButton : c.brandText)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.native, style: t.titleMedium),
                      Text(language.english, style: t.bodySmall),
                    ],
                  ),
                ),
                if (!live)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: ShapeDecoration(color: c.raised, shape: AppShapes.squircle(AppRadii.pill)),
                    child: Text(comingSoon, style: t.labelSmall),
                  )
                else
                  // Filled blue circle with a white tick when chosen, an empty ring otherwise (screen 03).
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? c.brandButton : Colors.transparent,
                      border: Border.all(color: selected ? c.brandButton : c.textMuted, width: 1.6),
                    ),
                    child: selected ? Icon(LucideIcons.check, size: 15, color: c.onButton) : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
