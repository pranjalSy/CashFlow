import 'package:flutter/material.dart';

import '../../core/theme/app_shapes.dart';

/// Scrollable tab body with a big title, side gutters and room for the floating bottom bar.
class TabPage extends StatelessWidget {
  const TabPage({super.key, this.title, this.header, required this.children, this.controller});

  final String? title;
  final Widget? header;
  final List<Widget> children;
  final ScrollController? controller;

  /// Space kept free under the content for the glass bottom bar.
  static const bottomBarSpace = 120.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, bottomBarSpace),
        children: [
          ?header,
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: AppSpacing.sm),
              child: Text(title!, style: Theme.of(context).textTheme.displaySmall),
            ),
          ...children,
        ],
      ),
    );
  }
}
