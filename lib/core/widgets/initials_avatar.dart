import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round avatar with the initials of [name], for people without a photo.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 26});

  final String name;
  final double radius;

  /// First letter of the first two words, in capitals ("Ana Pérez" -> "AP").
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first));
    final initials = letters.join().toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondary50,
      child: Text(
        initialsOf(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.secondary500,
        ),
      ),
    );
  }
}
