import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White app bar with dark title and back arrow. The global theme paints the
/// bar blue with white text, so a bar on a white page must use this widget or
/// its title and back button become invisible.
class LightAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const LightAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink900,
      surfaceTintColor: Colors.transparent,
      title: Text(title),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w800,
      ),
      actions: actions,
    );
  }
}
