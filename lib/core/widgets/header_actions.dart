import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// One icon action of [HeaderActions] (profile, sign out...).
class HeaderAction {
  const HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.teal700,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;
}

/// Account actions of a home header on their own white pill. The icons stay
/// readable over the decorative bubbles (an icon straight on the blue bubble
/// has about 1.6:1 contrast), related actions read as one group and each
/// target keeps at least 48 dp. It only takes the width of its buttons, so
/// next to an `Expanded` greeting it never overflows on narrow phones, and it
/// grows a little on tablets.
class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key, required this.actions});

  final List<HeaderAction> actions;

  /// Space between the top of the safe area and the header, so the pill does
  /// not sit against the edge of the screen. Shared by the three home screens.
  static const double topInset = AppSpacing.xl + AppSpacing.sm;

  static const double _phoneButton = 48;
  static const double _tabletButton = 56;
  static const double _phoneIcon = 24;
  static const double _tabletIcon = 28;

  @override
  Widget build(BuildContext context) {
    final tablet = AppLayout.isTablet(context);
    final buttonSize = tablet ? _tabletButton : _phoneButton;
    final iconSize = tablet ? _tabletIcon : _phoneIcon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: AppColors.teal50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              SizedBox(
                height: buttonSize / 2,
                child: const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.teal50,
                ),
              ),
            IconButton(
              onPressed: actions[i].onPressed,
              tooltip: actions[i].tooltip,
              iconSize: iconSize,
              constraints: BoxConstraints.tightFor(
                width: buttonSize,
                height: buttonSize,
              ),
              icon: Icon(actions[i].icon, color: actions[i].color),
            ),
          ],
        ],
      ),
    );
  }
}
