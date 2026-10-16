import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

/// Dim + blur behind sheets and popups: one blur layer only (DESIGN_DECISIONS B4).
Widget _scrim(BuildContext context, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: ColoredBox(color: context.colors.scrim),
    ),
  );
}

/// Solid bottom sheet with a handle (B3). Returns the value passed to `Navigator.pop`.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: _scrim(context, curved)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: AppSheetBody(child: Builder(builder: builder)),
            ),
          ),
        ],
      );
    },
  );
}

/// The sheet surface itself (also usable inline in previews).
class AppSheetBody extends StatelessWidget {
  const AppSheetBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Material(
      color: c.sheet,
      shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: ShapeDecoration(color: c.border, shape: AppShapes.squircle(AppRadii.pill)),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Centered solid popup (due popups, "Was this you?").
Future<T?> showAppPopup<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: dismissible ? () => Navigator.of(context).maybePop() : null, child: _scrim(context, animation)),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(curved),
              child: FadeTransition(
                opacity: animation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Material(
                    color: context.colors.sheet,
                    shape: AppShapes.squircle(30),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      child: Builder(builder: builder),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Compact 54 px snackbar in brand blue with an optional action and ×, 5 s (DESIGN_DECISIONS G6).
/// Shown above everything, including open sheets.
class CompactSnackbar {
  CompactSnackbar._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    String? detail,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    hide();
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 6,
        right: 6,
        bottom: 19 + MediaQuery.paddingOf(context).bottom,
        child: CompactSnackbarView(
          message: message,
          detail: detail,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  hide();
                  onAction();
                },
          onClose: hide,
        ),
      ),
    );
    overlay.insert(_entry!);
    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class CompactSnackbarView extends StatelessWidget {
  const CompactSnackbarView({super.key, required this.message, this.detail, this.actionLabel, this.onAction, required this.onClose});

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    // Live region: TalkBack reads it when it appears; the action is a real button.
    return Semantics(
      container: true,
      liveRegion: true,
      explicitChildNodes: true,
      child: Material(
        color: c.brandButton,
        shape: AppShapes.squircle(18),
        elevation: 8,
        shadowColor: c.brandButton.withValues(alpha: 0.6),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(color: c.onButton),
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: c.onButton.withValues(alpha: 0.85)),
                      ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    button: true,
                    child: Material(
                      color: Colors.white,
                      shape: AppShapes.squircle(AppRadii.pill),
                      child: InkWell(
                        onTap: onAction,
                        customBorder: AppShapes.squircle(AppRadii.pill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(actionLabel!, style: t.titleSmall?.copyWith(color: const Color(0xFF2B4BC7))),
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: c.onButton, size: 18),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
