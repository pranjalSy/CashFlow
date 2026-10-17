import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'number_pad.dart';

/// Four PIN dots + number pad. Calls [onComplete] as soon as 4 digits are in (C4).
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onComplete, this.error, this.enabled = true, this.keyHeight = 58, this.hint, this.footnote, this.expand = false});

  /// Grey line under the dots when there is no error ("Avoid easy PINs…", screen 06).
  final String? hint;

  /// Small line just above the keys ("Stored only on this phone…", screen 06).
  final Widget? footnote;

  /// Dots at the top and keys at the bottom of the space given (needs a bounded height).
  final bool expand;

  final Future<void> Function(String pin) onComplete;

  /// Red message under the dots; the dots shake when it changes.
  final String? error;
  final bool enabled;
  final double keyHeight;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _busy = false;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && widget.error != oldWidget.error) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void clear() => setState(() => _pin = '');

  Future<void> _digit(String d) async {
    if (!widget.enabled || _busy || _pin.length >= 4 || d == '.') return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      _busy = true;
      final pin = _pin;
      await widget.onComplete(pin);
      if (mounted) setState(() => _pin = '');
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Semantics(
            label: '${_pin.length} of 4',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 15,
                    height: 15,
                    decoration: ShapeDecoration(
                      color: i < _pin.length ? c.brandButton : Colors.transparent,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: widget.error != null ? c.expense : (i < _pin.length ? c.brandButton : c.textMuted),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: Center(
            child: widget.error == null
                ? (widget.hint == null ? null : Text(widget.hint!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))
                : Text(
                    widget.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.expense, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        if (widget.expand) const Spacer() else const SizedBox(height: AppSpacing.xs),
        if (widget.footnote != null) ...[widget.footnote!, const SizedBox(height: AppSpacing.xs)],
        NumberPad(
          showDot: false,
          phoneStyle: true,
          keyHeight: widget.keyHeight,
          onDigit: _digit,
          onBackspace: () {
            if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
          },
        ),
      ],
    );
  }
}
