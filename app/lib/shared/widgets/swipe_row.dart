import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

/// Swipe right-to-left to reveal Edit and Delete (DESIGN_DECISIONS E3–E5).
/// Past [fullSwipe] of the width, Delete fills the row and [onDelete] fires on release;
/// the caller shows the confirm sheet (E4). Only one row is open at a time.
class SwipeActionRow extends StatefulWidget {
  const SwipeActionRow({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
    this.radius = AppRadii.md,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;
  final double radius;

  static const double fullSwipe = 0.6;
  static const double buttonWidth = 68;
  static const double gap = 8;
  static const double openOffset = buttonWidth * 2 + gap * 2;

  @override
  State<SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<SwipeActionRow> with SingleTickerProviderStateMixin {
  static _SwipeActionRowState? _open;

  late final AnimationController _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  double _reveal = 0;
  double _from = 0;
  double _to = 0;
  bool _full = false;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      final v = Curves.easeOutBack.transform(_settle.value).clamp(0.0, 1.2);
      setState(() => _reveal = _from + (_to - _from) * v);
    });
  }

  @override
  void dispose() {
    if (_open == this) _open = null;
    _settle.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _from = _reveal;
    _to = target;
    _settle.forward(from: 0);
  }

  void close() {
    if (_open == this) _open = null;
    _animateTo(0);
  }

  void _onStart(DragStartDetails _) {
    if (_open != null && _open != this) _open!.close();
    _settle.stop();
  }

  void _onUpdate(DragUpdateDetails d, double width) {
    var r = (_reveal - d.delta.dx).clamp(0.0, width * 1.1);
    final full = r > width * SwipeActionRow.fullSwipe;
    if (full != _full) {
      _full = full;
      if (full) HapticFeedback.mediumImpact();
    }
    setState(() => _reveal = r);
  }

  void _onEnd(DragEndDetails _, double width) {
    if (_reveal > width * SwipeActionRow.fullSwipe) {
      _open = this;
      _animateTo(SwipeActionRow.openOffset);
      widget.onDelete();
    } else if (_reveal > 60) {
      _open = this;
      _animateTo(SwipeActionRow.openOffset);
    } else {
      close();
    }
    _full = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final room = (_reveal - SwipeActionRow.gap).clamp(0.0, double.infinity);
        final full = _reveal > width * SwipeActionRow.fullSwipe;
        final each = ((room - SwipeActionRow.gap) / 2).clamp(0.0, SwipeActionRow.buttonWidth + 20);
        final editW = full ? 0.0 : each;
        final deleteW = full ? room : (room - SwipeActionRow.gap - editW).clamp(each, double.infinity);
        final scale = (0.6 + _reveal / 220).clamp(0.6, 1.0);
        return GestureDetector(
          onHorizontalDragStart: _onStart,
          onHorizontalDragUpdate: (d) => _onUpdate(d, width),
          onHorizontalDragEnd: (d) => _onEnd(d, width),
          onTap: _reveal > 0 ? close : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(width: editW, color: c.brandButton, icon: Icons.edit_rounded, label: widget.editLabel, scale: scale, radius: widget.radius, onTap: () {
                      close();
                      widget.onEdit();
                    }),
                    if (editW > 0) const SizedBox(width: SwipeActionRow.gap),
                    _ActionButton(width: deleteW, color: c.expenseButton, icon: Icons.delete_outline_rounded, label: widget.deleteLabel, scale: scale, radius: widget.radius, onTap: widget.onDelete),
                  ],
                ),
              ),
              Transform.translate(offset: Offset(-_reveal, 0), child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.label,
    required this.scale,
    required this.radius,
    required this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String label;
  final double scale;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (width <= 0) return const SizedBox.shrink();
    final c = context.colors;
    return SizedBox(
      width: width,
      child: Opacity(
        opacity: (width / 50).clamp(0.0, 1.0),
        child: Material(
          color: color,
          shape: AppShapes.squircle(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: c.onButton, size: 22),
                    const SizedBox(height: 2),
                    Text(label, maxLines: 1, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onButton, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
