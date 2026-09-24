import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({super.key, required this.currentIndex, this.onTap});

  void _handleDefaultNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Only "home" has a safe default (no extra context needed). Menu and
    // wallet require studentId/wallet data that this generic widget
    // doesn't have — screens that show this bar MUST pass their own
    // onTap for indices 1 and 2, or those taps do nothing.
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brand500,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context: context, index: 0, icon: Icons.home),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.restaurant_menu,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.attach_money,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        } else {
          _handleDefaultNavigation(context, index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand700 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
