import 'package:flutter/material.dart';

import '../../core/theme/app_shapes.dart';

/// Initials in a coloured box (people in udhar lists) or circle (contacts).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, required this.color, required this.tint, this.size = 40, this.circle = false});

  final String name;
  final Color color;
  final Color tint;
  final double size;
  final bool circle;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    return (parts.length == 1 ? first : '$first${parts.last.characters.first}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: tint, shape: circle ? const CircleBorder() : AppShapes.squircle(size * 0.33)),
        child: Center(
          child: Text(
            initialsOf(name),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontSize: size * 0.33),
          ),
        ),
      ),
    );
  }
}
