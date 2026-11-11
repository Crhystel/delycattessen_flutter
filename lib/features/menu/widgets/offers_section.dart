import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/menu_models.dart';
import 'catalog_stock_badges.dart';
import 'combo_carousel.dart';
import 'combo_offer_card.dart';

/// "Ofertas de hoy": the combos (with their dishes) in force. It goes inside the scroll of the product list (see
/// `ResponsiveItemList.header`), so it never takes fixed space from the
/// products. On tablets the cards use two columns.
class OffersSection extends StatelessWidget {
  final CatalogOffers offers;

  /// Catalog products by id, for photos and prices.
  final Map<int, MenuItem> itemsById;

  /// POS only: adds a combo to the cart. Null in the consult-only catalogs.
  final ValueChanged<Combo>? onAddCombo;

  /// POS only: units of a combo already in the cart.
  final int Function(Combo combo)? comboQuantity;

  /// POS only: a dish of the combo has an allergen of the customer.
  final bool Function(Combo combo)? isComboBlocked;

  /// Opens the detail of a combo (tapping its card).
  final ValueChanged<Combo>? onComboTap;

  /// Parents: the combos go in a carousel ("Combos de hoy"). Otherwise they
  /// are one list of cards.
  final bool carousel;

  /// How the units left of each combo card are announced (POS: exact stock).
  /// By default "Quedan N".
  final StockBadgeBuilder stockBadge;

  const OffersSection({
    super.key,
    required this.offers,
    required this.itemsById,
    this.onAddCombo,
    this.comboQuantity,
    this.isComboBlocked,
    this.onComboTap,
    this.carousel = false,
    this.stockBadge = CatalogStockBadges.low,
  });

  static const double _minCardWidth = 340;
  static const int _maxColumns = 2;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    if (carousel) {
      return ComboCarousel(combos: offers.combos, onComboTap: onComboTap);
    }
    final cards = <Widget Function()>[
      for (final combo in offers.combos)
        () => ComboOfferCard(
          combo: combo,
          itemsById: itemsById,
          onAdd: onAddCombo == null ? null : () => onAddCombo!(combo),
          inCart: comboQuantity?.call(combo) ?? 0,
          blocked: isComboBlocked?.call(combo) ?? false,
          onTap: onComboTap == null ? null : () => onComboTap!(combo),
          stockBadge: stockBadge,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_title(context, 'Ofertas de hoy'), _grid(cards)],
      ),
    );
  }

  Widget _title(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink900,
        ),
      ),
    );
  }

  Widget _grid(List<Widget Function()> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppLayout.columnsFor(
          constraints.maxWidth,
          minItemWidth: _minCardWidth,
          maxColumns: _maxColumns,
        );
        final cardWidth =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final buildCard in cards)
              SizedBox(width: cardWidth, child: buildCard()),
          ],
        );
      },
    );
  }
}
