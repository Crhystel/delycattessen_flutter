import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/subpage_header.dart';
import '../../wallet/screens/transaction_history_screen.dart';
import '../models/menu_models.dart';

/// Detalle de un pedido tipo factura: cabecera morada con el estado y el total,
/// fecha, hijo, lugar y pago, la tabla de productos (cantidad, producto y
/// precio) y el desglose. Con [walletId] ofrece ir a los movimientos de la
/// billetera del hijo.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order, this.walletId});

  final OrderEntry order;

  /// Billetera del hijo (si se conoce) para el enlace a sus movimientos.
  final int? walletId;

  static const double _maxWidth = 560;

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String get _place =>
      order.origin == OrderOrigin.pointOfSale ? 'En caja' : 'Preorden (app)';

  double get _subtotal => order.items.isEmpty
      ? order.totalAmount
      : order.items.fold(0.0, (sum, i) => sum + i.priceAtPurchase * i.quantity);

  double get _discount => math.max(0, _subtotal - order.totalAmount);

  void _openMovements(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen.forWallet(
          walletId: walletId!,
          childName: order.studentName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt.toLocal();
    final date =
        '${DateFormatter.formatShort(created)} · ${DateFormat('HH:mm').format(created)}';
    final delivery = order.deliveryDate.isEmpty
        ? null
        : DateFormatter.formatLong(
            DateFormatter.parseIsoDate(order.deliveryDate),
          );

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: ResponsiveCenter(
        maxWidth: _maxWidth,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SubpageHeader(title: 'Detalle del pedido'),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink900.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              order: order,
                              total: _money(order.totalAmount),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 11,
                              ),
                              child: Column(
                                children: [
                                  _Field(label: 'Fecha', value: date),
                                  if (delivery != null)
                                    _Field(label: 'Entrega', value: delivery),
                                  _Field(
                                    label: 'Hijo',
                                    value: order.studentName,
                                  ),
                                  _Field(label: 'Lugar', value: _place),
                                  if (order.paymentLabel.isNotEmpty)
                                    _Field(
                                      label: 'Pago',
                                      value: order.paymentLabel,
                                    ),
                                ],
                              ),
                            ),
                            const _TicketDivider(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                              child: Column(
                                children: [
                                  const _Row(
                                    quantity: 'Cant.',
                                    name: 'Producto',
                                    price: 'Precio',
                                    header: true,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                  for (final item in order.items)
                                    _Row(
                                      quantity: '${item.quantity}',
                                      name: item.dishName,
                                      price: _money(item.priceAtPurchase),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 18,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _Total(
                                    label: 'Subtotal',
                                    value: _money(_subtotal),
                                  ),
                                  // Solo cuando hubo descuento: sin él el
                                  // desglose es Subtotal y Total, como el diseño.
                                  if (_discount > 0) ...[
                                    const SizedBox(height: 8),
                                    _Total(
                                      label: 'Descuento',
                                      value: _money(_discount),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.only(top: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: AppColors.ink900,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('Total', style: AppText.price),
                                        Text(
                                          _money(order.totalAmount),
                                          style: AppText.amount.copyWith(
                                            color: AppColors.brand700,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (walletId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                            onPressed: () => _openMovements(context),
                            child: Text(
                              'Ver en movimientos de la billetera',
                              style: AppText.link,
                            ),
                          ),
                        ),
                    ],
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

/// Cabecera morada: estado en una píldora blanca, el total grande y el número
/// del pedido, con dos círculos decorativos (ámbar y azul) detrás.
class _Header extends StatelessWidget {
  const _Header({required this.order, required this.total});

  final OrderEntry order;
  final String total;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (order.status) {
      PreOrderStatus.pending => (AppColors.warning700, Icons.schedule),
      PreOrderStatus.delivered => (AppColors.success700, Icons.check),
      PreOrderStatus.canceled => (AppColors.danger700, Icons.close),
    };
    // The circles are laid out against the whole purple box (not inside its
    // padding), so the box clips them at its own edges, as in the design.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
      child: ColoredBox(
        color: AppColors.secondary500,
        child: Stack(
          children: [
            const Positioned(
              top: -40,
              right: -30,
              child: _Dot(size: 110, color: AppColors.brand500, opacity: 0.9),
            ),
            const Positioned(
              bottom: -50,
              left: -30,
              child: _Dot(size: 100, color: AppColors.teal500, opacity: 0.85),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: color),
                          const SizedBox(width: 6),
                          Text(
                            order.statusDisplay,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      total,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pedido N.º ${order.id}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Línea punteada con una muesca a cada lado, como el corte de un ticket.
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: 10,
            child: CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _DashedLinePainter(),
            ),
          ),
          const Positioned(left: -12, top: 0, child: _Notch()),
          const Positioned(right: -12, top: 0, child: _Notch()),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.ink50,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lineStrong
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 1),
        Offset(math.min(x + dash, size.width), 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  static const double _fontSize = 14.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppText.secondary.copyWith(fontSize: _fontSize),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.rowTitle.copyWith(fontSize: _fontSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de la tabla de productos (o su cabecera). Columnas del diseño: cantidad
/// 40, producto flexible y precio alineado a la derecha.
class _Row extends StatelessWidget {
  const _Row({
    required this.quantity,
    required this.name,
    required this.price,
    this.header = false,
  });

  final String quantity;
  final String name;
  final String price;
  final bool header;

  static const double _quantityWidth = 40;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    const figures = [FontFeature.tabularFigures()];
    final headerStyle = AppText.caption.copyWith(fontWeight: FontWeight.w700);
    final bold = header
        ? headerStyle
        : AppText.rowTitle.copyWith(fontSize: 15, fontFeatures: figures);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: header ? 0 : 10,
      ).copyWith(bottom: header ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _quantityWidth,
            child: Text(quantity, style: bold),
          ),
          const SizedBox(width: _gap),
          Expanded(child: Text(name, style: bold)),
          const SizedBox(width: _gap),
          Text(price, textAlign: TextAlign.right, style: bold),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.secondary.copyWith(fontSize: 14.5)),
        Text(
          value,
          style: AppText.rowTitle.copyWith(
            fontSize: 14.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
