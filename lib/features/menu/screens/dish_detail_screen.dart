import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';
import '../utils/allergen_advisory.dart';
import '../widgets/allergen_section_card.dart';
import '../widgets/blocked_purchase_bar.dart';
import '../widgets/child_ordering_row.dart';
import '../widgets/detail_info_grid.dart';
import '../widgets/detail_scaffold.dart';
import '../widgets/detail_tag.dart';
import '../widgets/quantity_add_bar.dart';

/// Detail of a dish of the monthly menu. It always opens and always shows its
/// allergens; what the [advisory] says decides whether it can be ordered.
class DishDetailScreen extends StatelessWidget {
  final MenuDish dish;

  /// Adds [dish] with the chosen quantity. Null: read only (no bottom bar).
  final Function(int)? onAdd;

  /// Day the dish is served; without it the date cards are left out.
  final DateTime? servedDate;

  final AllergenAdvisory advisory;

  /// Name of the child the order is for ("Pidiendo para").
  final String? orderingFor;

  /// Opens the child picker; true when the child changed (the detail then
  /// closes, as it belonged to the previous child).
  final Future<bool> Function()? onChangeChild;

  const DishDetailScreen({
    super.key,
    required this.dish,
    this.onAdd,
    this.servedDate,
    this.advisory = const AllergenAdvisory(),
    this.orderingFor,
    this.onChangeChild,
  });

  /// A default advisory knows nothing of the dish: never tell the user it has
  /// no allergens when it does.
  AllergenAdvisory get _effectiveAdvisory => advisory.allergens.isEmpty
      ? AllergenAdvisory.of(
          allergens: dish.allergens,
          conflicts: advisory.conflicts,
          audience: advisory.audience,
        )
      : advisory;

  Future<void> _changeChild(BuildContext context) async {
    final changed = await onChangeChild!();
    if (changed && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final date = servedDate;
    final childName = orderingFor;
    final change = onChangeChild;
    return DetailScaffold(
      tag: const DetailTag.neutral('Menú del mes'),
      imageUrl: dish.imageUrl,
      bottomBar: _buildBottomBar(context),
      children: [
        _Header(dish: dish),
        if (date != null)
          DetailInfoGrid(
            tiles: [
              DetailInfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Se sirve el',
                value: DateFormatter.formatWeekdayShortMonth(date),
              ),
              DetailInfoTile(
                icon: Icons.schedule,
                label: 'Pide hasta',
                // The backend only takes orders for future dates.
                value: DateFormatter.formatChip(
                  date.subtract(const Duration(days: 1)),
                ),
                tone: DetailInfoTone.amber,
              ),
            ],
          ),
        if (childName != null && change != null)
          ChildOrderingRow(
            name: childName,
            onChange: () => _changeChild(context),
          ),
        AllergenSectionCard(
          advisory: _effectiveAdvisory,
          subject: AllergenSubject.dish,
        ),
      ],
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    final add = onAdd;
    if (add == null) return null;
    if (advisory.hasConflict) {
      return BlockedPurchaseBar(
        label: advisory.blockedLabel,
        secondaryLabel: onChangeChild == null ? null : 'Pedir para otro hijo',
        onSecondary: onChangeChild == null ? null : () => _changeChild(context),
      );
    }
    return QuantityAddBar(unitPrice: dish.price, onAdd: add);
  }
}

class _Header extends StatelessWidget {
  final MenuDish dish;

  const _Header({required this.dish});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dish.name, style: AppText.detailTitle),
              if (dish.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dish.description, style: AppText.detailSubtitle),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '\$${dish.price.toStringAsFixed(2)}',
          maxLines: 1,
          style: AppText.detailPrice,
        ),
      ],
    );
  }
}
