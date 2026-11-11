import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'detail_bottom_bar_shell.dart';

/// Bottom bar of a detail screen when the item cannot be bought: a disabled
/// button with the reason ([label], "No disponible para Pepito") and,
/// optionally, a link under it ("Pedir para otro hijo").
class BlockedPurchaseBar extends StatelessWidget {
  final String label;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const BlockedPurchaseBar({
    super.key,
    required this.label,
    this.secondaryLabel,
    this.onSecondary,
  });

  static const double _buttonHeight = 54;
  static const double _linkHeight = 36;

  @override
  Widget build(BuildContext context) {
    final link = secondaryLabel;
    return DetailBottomBarShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppColors.ink50,
              disabledForegroundColor: AppColors.muted,
              minimumSize: const Size.fromHeight(_buttonHeight),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.button.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          if (link != null)
            TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(_linkHeight),
              ),
              child: Text(link, style: AppText.link),
            ),
        ],
      ),
    );
  }
}
