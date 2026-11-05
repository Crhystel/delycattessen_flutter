import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Round avatar with the initials of [name], for people without a photo.
/// Parents register with only an email, so when there is no name it shows the
/// first letter of [fallback] (the email) and, as a last resort, a person icon
/// (never a question mark).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.fallback,
    this.radius = 26,
  });

  final String name;

  /// Text to take the letter from when [name] is empty (e.g. the email).
  final String? fallback;
  final double radius;

  /// First letter of the first two words, in capitals ("Ana Pérez" -> "AP").
  /// Empty when [name] has no letters.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first));
    return letters.join().toUpperCase();
  }

  /// What the avatar shows: the initials of [name], else the first letter of
  /// [fallback], else an empty string (the avatar then shows an icon).
  String get label {
    final fromName = initialsOf(name);
    if (fromName.isNotEmpty) return fromName;
    final fromFallback = initialsOf(fallback ?? '');
    return fromFallback.isEmpty ? '' : fromFallback.substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final text = label;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondary50,
      child: text.isEmpty
          ? Icon(Icons.person, color: AppColors.secondary500, size: radius)
          : Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary500,
              ),
            ),
    );
  }
}
