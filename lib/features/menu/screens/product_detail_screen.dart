import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/menu_models.dart';
import '../utils/allergen_advisory.dart';
import '../utils/product_stock_label.dart';
import '../widgets/allergen_section_card.dart';
import '../widgets/blocked_purchase_bar.dart';
import '../widgets/combo_link_section.dart';
import '../widgets/detail_chip.dart';
import '../widgets/detail_info_grid.dart';
import '../widgets/detail_scaffold.dart';
import '../widgets/detail_section_card.dart';
import '../widgets/detail_tag.dart';
import '../widgets/quantity_add_bar.dart';

/// Detail of a product. The allergen card is always shown; when the person it
/// is checked against has one of them registered, the purchase bar is blocked
/// instead of hidden, so the information stays readable.
class ProductDetailScreen extends StatelessWidget {
  final MenuItem item;

  /// Si es nulo la pantalla es de solo consulta (sin cantidad ni botón añadir).
  final ValueChanged<int>? onAdd;

  /// Allergens of the item and the ones the user has registered.
  final AllergenAdvisory advisory;

  /// Combos that include this product ("También en combo").
  final List<Combo> combos;

  /// Opens a combo of [combos]; null = the cards do not navigate.
  final ValueChanged<Combo>? onComboTap;

  /// POS: the stock tile shows the exact count instead of "Disponible".
  final bool exactStock;

  /// POS: units still addable once the cart is taken out. It caps the quantity
  /// bar and replaces the stock of the item; null = no cap.
  final int? maxQuantity;

  const ProductDetailScreen({
    super.key,
    required this.item,
    this.onAdd,
    this.advisory = const AllergenAdvisory(),
    this.combos = const <Combo>[],
    this.onComboTap,
    this.exactStock = false,
    this.maxQuantity,
  });

  Widget? _bottomBar() {
    final add = onAdd;
    if (add == null) return null;
    if (advisory.hasConflict) {
      return BlockedPurchaseBar(label: advisory.blockedLabel);
    }
    return QuantityAddBar(
      unitPrice: item.price,
      onAdd: add,
      maxQuantity: maxQuantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      // DetailScaffold always draws a tag; an uncategorized product says so.
      tag: DetailTag.neutral(
        item.category.isEmpty ? 'Producto' : item.category,
      ),
      imageUrl: item.imageUrl,
      bottomBar: _bottomBar(),
      children: [
        _Header(item: item),
        DetailInfoGrid(
          tiles: [
            DetailInfoTile(
              icon: Icons.inventory_2_outlined,
              label: 'Disponibles hoy',
              value: productStockLabel(
                maxQuantity ?? item.stock,
                exact: exactStock,
              ),
            ),
            const DetailInfoTile(
              icon: Icons.storefront_outlined,
              label: 'Se compra',
              value: 'En caja',
              tone: DetailInfoTone.blue,
            ),
          ],
        ),
        AllergenSectionCard(
          advisory: advisory,
          subject: AllergenSubject.product,
        ),
        if (item.ingredients.isNotEmpty)
          DetailSectionCard(
            title: 'Ingredientes',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final i in item.ingredients)
                  DetailChip(i.name, design: true),
              ],
            ),
          ),
        if (combos.isNotEmpty)
          ComboLinkSection(combos: combos, onComboTap: onComboTap ?? (_) {}),
      ],
    );
  }
}

/// Name and description on the left, price on the right. The name takes
/// whatever the price leaves, so a long name or a large font never overflows.
class _Header extends StatelessWidget {
  final MenuItem item;

  const _Header({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppText.detailTitle),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(item.description, style: AppText.detailSubtitle),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '\$${item.price.toStringAsFixed(2)}',
          maxLines: 1,
          style: AppText.detailPrice,
        ),
      ],
    );
  }
}
