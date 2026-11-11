import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Fila de la lista de Pedidos: foto del primer producto, "1× Pollo asado",
/// dónde y cuándo, el estado y el total. Tocarla abre el detalle del pedido.
///
/// Por defecto es una tarjeta con foto y borde ámbar (pedido pendiente, con el
/// estado bajo el texto). Con [grouped] es solo la fila, sin foto, para ir
/// dentro de la tarjeta de un día (el estado va junto al total).
class OrderRow extends StatelessWidget {
  const OrderRow({
    super.key,
    required this.order,
    required this.onTap,
    this.grouped = false,
  });

  final OrderEntry order;
  final VoidCallback onTap;
  final bool grouped;

  static const double _photoSize = 52;

  /// Tope del ancho de precio y estado: con letra muy grande se recortan con
  /// puntos suspensivos en vez de desbordar la fila.
  static const double _rightColumnMaxWidth = 112;

  /// "1× Pollo asado" o "1× Pollo asado +2 más".
  String get _title {
    if (order.items.isEmpty) return 'Pedido #${order.id}';
    final first = order.items.first;
    final extra = order.items.length - 1;
    final base = '${first.quantity}× ${first.dishName}';
    return extra > 0 ? '$base +$extra más' : base;
  }

  String get _subtitle {
    if (order.origin == OrderOrigin.preorder) {
      final date = order.deliveryDate.isEmpty
          ? null
          : DateFormatter.parseIsoDate(order.deliveryDate);
      return date == null
          ? 'Preorden'
          : 'Para el ${DateFormatter.formatChip(date).toLowerCase()} · Preorden';
    }
    final time = TimeOfDay.fromDateTime(order.createdAt.toLocal());
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final payment = order.paymentLabel.isEmpty
        ? ''
        : ' · ${order.paymentLabel}';
    return '$hh:$mm · En caja$payment';
  }

  @override
  Widget build(BuildContext context) {
    final chip = OrderStatusChip(
      status: order.status,
      label: order.statusDisplay,
    );
    final price = Text(
      '\$${order.totalAmount.toStringAsFixed(2)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.itemTitle.copyWith(
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    final content = Padding(
      padding: grouped
          ? const EdgeInsets.fromLTRB(14, 12, 12, 12)
          : const EdgeInsets.all(14),
      child: Row(
        children: [
          if (!grouped) ...[
            OrderPhoto(
              imageUrl: order.items.firstOrNull?.imageUrl,
              size: _photoSize,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.secondary,
                ),
                if (!grouped) ...[const SizedBox(height: 4), chip],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _rightColumnMaxWidth),
            child: grouped
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [price, const SizedBox(height: 3), chip],
                  )
                : price,
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    );

    if (grouped) return InkWell(onTap: onTap, child: content);

    return Material(
      color: Colors.white,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.brandBorder, width: 1.5),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Foto cuadrada de un producto del pedido. Sin foto (o si no carga) muestra
/// un marcador neutro.
class OrderPhoto extends StatelessWidget {
  const OrderPhoto({super.key, required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final cache = AppImageCacheHelper.cacheSize(context, size);
    const placeholder = ColoredBox(
      color: AppColors.ink50,
      child: Icon(Icons.fastfood, color: AppColors.secondary500),
    );
    return ClipRRect(
      borderRadius: AppRadius.fieldAll,
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: cache,
                memCacheHeight: cache,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// Chip de estado del pedido (Pendiente / Entregado / Cancelado).
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, required this.label});

  final PreOrderStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      PreOrderStatus.pending => (AppColors.brand700, AppColors.brand50),
      PreOrderStatus.delivered => (AppColors.success700, AppColors.successBg),
      PreOrderStatus.canceled => (AppColors.danger700, AppColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.badge.copyWith(color: foreground),
      ),
    );
  }
}
