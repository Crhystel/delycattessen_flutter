import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/menu_models.dart';

/// Tarjeta de un platillo del menú del mes: foto, nombre, descripción, chip
/// "Ver alérgenos" (rojo si choca con las alergias del hijo), precio y el botón
/// "Agregar / Agregado". Tocar la tarjeta abre el detalle del platillo. Sin
/// [onToggle] la tarjeta es de solo consulta (estudiante): no hay botón.
class MenuDishCard extends StatelessWidget {
  const MenuDishCard({
    super.key,
    required this.dish,
    required this.onTap,
    required this.onShowAllergens,
    this.inCart = false,
    this.onToggle,
  });

  final MenuDish dish;

  /// El platillo ya está en el carrito.
  final bool inCart;
  final VoidCallback onTap;

  /// Agrega o quita el platillo (1 unidad). Nulo: solo consulta, sin botón.
  final VoidCallback? onToggle;
  final VoidCallback onShowAllergens;

  static const double _imageSize = 104;

  @override
  Widget build(BuildContext context) {
    final blocked = dish.hasStudentAllergens;
    final url = dish.imageUrl;

    return Opacity(
      opacity: blocked ? 0.7 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            // IntrinsicHeight: the price and the button stick to the bottom of
            // the card, whichever is taller, the photo or the texts.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Align: the photo keeps its size when the texts are taller.
                  Align(
                    alignment: Alignment.topCenter,
                    widthFactor: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: _imageSize,
                        height: _imageSize,
                        child: AppNetworkImage(
                          url: url,
                          width: _imageSize,
                          height: _imageSize,
                          error: const _Placeholder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.cardTitle,
                            ),
                            if (dish.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                dish.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.secondaryLg,
                              ),
                            ],
                            if (dish.allergens.isNotEmpty || blocked) ...[
                              const SizedBox(height: 4),
                              _AllergenChip(
                                blocked: blocked,
                                onTap: onShowAllergens,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          spacing: 8,
                          children: [
                            Text(
                              '\$${dish.price.toStringAsFixed(2)}',
                              style: AppText.price.copyWith(
                                fontSize: 18,
                                color: AppColors.brand700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (!blocked && onToggle != null)
                              _AddButton(added: inCart, onTap: onToggle!),
                          ],
                        ),
                      ],
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

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.blocked, required this.onTap});

  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: blocked ? AppColors.dangerBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: blocked ? AppColors.danger700 : AppColors.warning700,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                blocked ? 'Contiene alérgenos' : 'Ver alérgenos',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: blocked ? AppColors.danger700 : AppColors.warning700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.added, required this.onTap});

  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: added ? 'Quitar del pedido' : 'Agregar al pedido',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: added ? AppColors.secondary500 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: added
                ? null
                : Border.all(color: AppColors.secondary500, width: 1.5),
          ),
          // Con letra muy grande el contenido se reduce en vez de desbordar.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  added ? Icons.check : Icons.add,
                  size: 16,
                  color: added ? Colors.white : AppColors.secondary500,
                ),
                const SizedBox(width: 6),
                Text(
                  added ? 'Agregado' : 'Agregar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: added ? Colors.white : AppColors.secondary500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.ink50,
      child: Icon(Icons.fastfood, color: AppColors.secondary500),
    );
  }
}
