import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../utils/pos_home_layout.dart';

/// "Venta rápida": starts a sale without identifying the customer.
class PosQuickSaleButton extends StatelessWidget {
  const PosQuickSaleButton({
    super.key,
    required this.metrics,
    required this.onTap,
  });

  final PosHomeMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.fullAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.quickActionShadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: AppColors.quickAction,
        borderRadius: AppRadius.fullAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.buttonHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: m.buttonPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: m.buttonIconSize),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Venta rápida',
                      style: AppText.button.copyWith(
                        fontSize: m.buttonTextSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
