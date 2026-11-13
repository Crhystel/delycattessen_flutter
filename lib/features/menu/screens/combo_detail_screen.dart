import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';
import '../utils/allergen_advisory.dart';
import '../widgets/allergen_section_card.dart';
import '../widgets/blocked_purchase_bar.dart';
import '../widgets/catalog_item_card.dart';
import '../widgets/catalog_stock_badges.dart';
import '../widgets/detail_info_grid.dart';
import '../widgets/detail_scaffold.dart';
import '../widgets/detail_section_card.dart';
import '../widgets/detail_tag.dart';
import '../widgets/offer_thumbnail.dart';
import '../widgets/other_combos_grid.dart';
import '../widgets/quantity_add_bar.dart';

/// Detail of a combo: photo, name and price (with the regular one crossed out
/// and the saving), what it includes and its allergens, which are always
/// shown. With [onAdd] (POS) it has the bottom bar: the quantity bar, or a
/// blocked one when the audience has an allergen of the combo registered.
/// Without it (parents and teachers only consult the catalog) it is read-only.
class ComboDetailScreen extends StatelessWidget {
  final Combo combo;

  /// Catalog products by id, only for the photos and prices of the dishes.
  final Map<int, MenuItem> itemsById;

  /// Adds [quantity] combos to the cart; null in the consult-only catalogs.
  final ValueChanged<int>? onAdd;

  /// How the units left are announced; by default "Quedan N". The POS passes
  /// the exact stock.
  final StockBadgeBuilder stockBadge;

  /// What the allergens of the combo mean for whoever is looking at it.
  final AllergenAdvisory advisory;

  /// The "Otros combos" section; empty hides it.
  final List<Combo> otherCombos;

  /// Opens another combo; null makes those cards do nothing.
  final ValueChanged<Combo>? onComboTap;

  /// Units left to show and to cap the quantity bar instead of
  /// [Combo.availableQuantity] (POS: the stock once the cart is taken out).
  /// Null = the combo's own.
  final int? availableQuantity;

  const ComboDetailScreen({
    super.key,
    required this.combo,
    required this.itemsById,
    this.onAdd,
    this.stockBadge = CatalogStockBadges.low,
    this.advisory = const AllergenAdvisory(),
    this.otherCombos = const <Combo>[],
    this.onComboTap,
    this.availableQuantity,
  });

  int? get _available => availableQuantity ?? combo.availableQuantity;

  /// Photo of the combo, or the one of its first dish when it has none.
  String? get _imageUrl {
    if (combo.imageUrl != null) return combo.imageUrl;
    for (final dish in combo.items) {
      final url = itemsById[dish.productId]?.imageUrl;
      if (url != null) return url;
    }
    return null;
  }

  Widget? get _bottomBar {
    final add = onAdd;
    if (add == null) return null;
    if (advisory.hasConflict) {
      return BlockedPurchaseBar(label: advisory.blockedLabel);
    }
    return QuantityAddBar(
      unitPrice: combo.price,
      onAdd: add,
      maxQuantity: _available,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      tag: const DetailTag.combo(),
      imageUrl: _imageUrl,
      bottomBar: _bottomBar,
      children: [
        _Header(combo: combo, stockBadge: stockBadge, available: _available),
        DetailInfoGrid(
          tiles: [
            DetailInfoTile(
              icon: Icons.calendar_today_rounded,
              label: 'Válido hasta',
              value: DateFormatter.formatLongCapitalized(combo.endDate),
              tone: DetailInfoTone.amber,
            ),
            const DetailInfoTile(
              icon: Icons.storefront_rounded,
              label: 'Se compra',
              value: 'En caja',
              tone: DetailInfoTone.blue,
            ),
          ],
        ),
        _IncludesCard(combo: combo, itemsById: itemsById),
        AllergenSectionCard(advisory: advisory, subject: AllergenSubject.combo),
        if (otherCombos.isNotEmpty)
          OtherCombosGrid(
            combos: otherCombos,
            onComboTap: onComboTap ?? (_) {},
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Combo combo;
  final StockBadgeBuilder stockBadge;
  final int? available;

  const _Header({
    required this.combo,
    required this.stockBadge,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final stock = available == null || available! > 0
        ? stockBadge(available)
        : CatalogStockBadges.soldOut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(combo.name, style: AppText.detailTitle),
        const SizedBox(height: 6),
        // Wrap, not Row: a long price or a large system font never overflows.
        Wrap(
          spacing: AppSpacing.tile,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '\$${combo.price.toStringAsFixed(2)}',
              style: AppText.detailPrice,
            ),
            if (combo.hasSavings)
              Text(
                '\$${combo.regularPrice.toStringAsFixed(2)}',
                style: AppText.itemTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (combo.hasSavings)
              CatalogBadge(
                label: 'Ahorras \$${combo.savings.toStringAsFixed(2)}',
                background: AppColors.successBg,
                foreground: AppColors.success700,
                icon: Icons.local_offer_rounded,
              ),
            ?stock,
          ],
        ),
      ],
    );
  }
}

class _IncludesCard extends StatelessWidget {
  final Combo combo;
  final Map<int, MenuItem> itemsById;

  const _IncludesCard({required this.combo, required this.itemsById});

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Incluye',
      padded: false,
      child: Column(
        children: [
          for (var i = 0; i < combo.items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _DishRow(
              dish: combo.items[i],
              item: itemsById[combo.items[i].productId],
            ),
          ],
          if (combo.hasSavings)
            _SavingsStrip(combo: combo)
          else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  final ComboItem dish;
  final MenuItem? item;

  const _DishRow({required this.dish, required this.item});

  static const double _thumbSize = 52;

  @override
  Widget build(BuildContext context) {
    final price = item?.price;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      child: Row(
        children: [
          OfferThumbnail(imageUrl: item?.imageUrl, size: _thumbSize),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dish.quantity}× ${dish.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle,
                ),
                if (price != null)
                  Text(
                    '\$${price.toStringAsFixed(2)} por separado',
                    style: AppText.secondary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Por separado $7.00 / En combo $2.00" under the dishes.
class _SavingsStrip extends StatelessWidget {
  final Combo combo;

  const _SavingsStrip({required this.combo});

  @override
  Widget build(BuildContext context) {
    final style = AppText.noteBody.copyWith(color: AppColors.brand700);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        6,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.brand50,
        borderRadius: AppRadius.controlAll,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Text.rich(
            TextSpan(
              style: style,
              children: [
                const TextSpan(text: 'Por separado '),
                TextSpan(
                  text: '\$${combo.regularPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'En combo \$${combo.price.toStringAsFixed(2)}',
            style: style.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
