import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/menu_models.dart';
import 'combo_link_card.dart';
import 'detail_section_heading.dart';

/// "También en combo": a [ComboLinkCard] per combo that includes the product.
/// Draws nothing when [combos] is empty.
class ComboLinkSection extends StatelessWidget {
  final List<Combo> combos;
  final ValueChanged<Combo> onComboTap;

  const ComboLinkSection({
    super.key,
    required this.combos,
    required this.onComboTap,
  });

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DetailSectionHeading('También en combo'),
        for (final combo in combos) ...[
          const SizedBox(height: AppSpacing.tile),
          ComboLinkCard(combo: combo, onTap: () => onComboTap(combo)),
        ],
      ],
    );
  }
}
