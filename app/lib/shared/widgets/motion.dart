import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/money.dart';
import 'amount_text.dart';

/// Shared motion (FR-U7, TRD 14): short, transform/opacity only, off when the system asks
/// ("remove animations"). Kept in one place so every screen moves the same way.
abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 340);
  static const enter = Curves.easeOutCubic;

  static bool off(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Shrinks a little while pressed and springs back, like a real button. Optional light haptic.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.97, this.haptic = false});

  final Widget child;
  final bool enabled;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    if (v && widget.haptic) HapticFeedback.lightImpact();
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.off(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? Motion.fast : Motion.medium,
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Fades in and rises a few pixels when first shown. [index] staggers items in a list (40 ms each, first 8 only).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 14});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  // The stagger delay is part of the animation (an Interval), so no timers are left behind.
  late final int _delay = widget.index.clamp(0, 7) * 40;
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow + Duration(milliseconds: _delay));
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(_delay / (Motion.slow.inMilliseconds + _delay), 1, curve: Motion.enter),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.off(context) || widget.index > 7) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - a.value)), child: child),
      ),
    );
  }
}

/// Money that counts to its new value (450 ms) instead of jumping. Shows [masked] when amounts are hidden.
class CountUpAmount extends StatelessWidget {
  const CountUpAmount({
    super.key,
    required this.paise,
    this.size = 16,
    this.color,
    this.showPlus = false,
    this.masked,
    this.alignment = Alignment.centerLeft,
  });

  final int paise;
  final double size;
  final Color? color;
  final bool showPlus;
  final String? masked;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (masked != null) return AmountText(masked!, size: size, color: color, alignment: alignment);
    if (Motion.off(context)) return AmountText(Money.format(paise, showPlus: showPlus), size: size, color: color, alignment: alignment);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: paise.toDouble()), // counts up on first show, then from the old value
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => AmountText(Money.format(v.round(), showPlus: showPlus), size: size, color: color, alignment: alignment),
    );
  }
}

/// Soft rings that slowly "breathe" behind a hero icon (screen 07): scale + opacity only, 2.6 s loop.
/// Static when the system asks for less motion.
class BreathingRings extends StatefulWidget {
  const BreathingRings({super.key, required this.child, required this.color, this.size = 170});

  final Widget child;
  final Color color;
  final double size;

  @override
  State<BreathingRings> createState() => _BreathingRingsState();
}

class _BreathingRingsState extends State<BreathingRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.off(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (context, child) => Stack(alignment: Alignment.center, children: [
            for (final phase in const [0.0, 0.5])
              () {
                final v = (_c.value + phase) % 1;
                return Opacity(
                  opacity: (1 - v) * 0.35,
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * v,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color, width: 2)),
                    ),
                  ),
                );
              }(),
            child!,
          ]),
        ),
      ),
    );
  }
}

/// Gently floats up and down (screen 09). Static when the system asks for less motion.
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.distance = 5});

  final Widget child;
  final double distance;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.off(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeInOutSine);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: a,
        child: widget.child,
        builder: (context, child) => Transform.translate(offset: Offset(0, widget.distance * (a.value * 2 - 1)), child: child),
      ),
    );
  }
}
