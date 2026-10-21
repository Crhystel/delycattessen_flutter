import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/widgets/light_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../../children/providers/children_provider.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../utils/cart_rules.dart';
import '../widgets/cart_line_tile.dart';

class CartScreen extends StatefulWidget {
  final int studentId;
  final String deliveryDate; // "YYYY-MM-DD"
  final Map<int, int> cart;
  final List<MenuDish> dishes;
  final String childName;
  final double? childBalance;

  const CartScreen({
    super.key,
    required this.studentId,
    required this.deliveryDate,
    required this.cart,
    required this.dishes,
    this.childName = '',
    this.childBalance,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with NotificationMixin {
  final MenuService _menuService = MenuService();
  bool _isLoading = false;
  late Map<int, int> _editableCart;

  @override
  void initState() {
    super.initState();
    _editableCart = Map<int, int>.from(widget.cart);
  }

  void _updateQuantity(int dishId, int delta) {
    setState(() {
      final current = _editableCart[dishId] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _editableCart.remove(dishId);
      } else {
        _editableCart[dishId] = next;
      }
    });
  }

  /// Quita el platillo completo, sin importar su cantidad.
  void _removeLine(int dishId) {
    setState(() => _editableCart.remove(dishId));
  }

  List<MapEntry<MenuDish, int>> get _lines {
    final lines = <MapEntry<MenuDish, int>>[];
    for (final entry in _editableCart.entries) {
      final matches = widget.dishes.where((d) => d.id == entry.key);
      if (matches.isNotEmpty) lines.add(MapEntry(matches.first, entry.value));
    }
    return lines;
  }

  double get _total {
    return _lines.fold(0, (sum, line) => sum + (line.key.price * line.value));
  }

  List<MenuDish> get _unsafeCartItems {
    return _lines
        .map((line) => line.key)
        .where((dish) => dish.hasStudentAllergens)
        .toList();
  }

  void _showBlockedDialog() {
    final unsafe = _unsafeCartItems;
    final itemsList = unsafe.map((i) => i.name).join(', ');
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este estudiante';

    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'No se puede procesar el pedido',
      message:
          'El carrito contiene platillos no seguros para $childLabel: '
          '$itemsList. Quítalos antes de continuar.',
    );
  }

  String _formatDeliveryDate() {
    if (widget.deliveryDate.isEmpty) return '';
    try {
      final parsed = DateFormatter.parseIsoDate(widget.deliveryDate);
      return DateFormatter.formatLong(parsed);
    } catch (_) {
      return widget.deliveryDate;
    }
  }

  Future<void> _handlePayment() async {
    if (_unsafeCartItems.isNotEmpty) {
      _showBlockedDialog();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orderItems = _editableCart.entries
          .map((e) => PreOrderItem(dishId: e.key, quantity: e.value))
          .toList();
      final preOrder = PreOrder(
        studentId: widget.studentId,
        deliveryDate: widget.deliveryDate,
        items: orderItems,
      );

      await _menuService.createPreOrder(preOrder);

      if (!mounted) return;
      await context.read<ChildrenProvider>().refresh();

      if (!mounted) return;
      showSuccessSnackBar(
        'Tu pedido ha sido registrado (-\$${_total.toStringAsFixed(2)})',
        title: '¡Pago Exitoso!',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceFirst('Exception: ', '');
      showErrorSnackBar(rawError, title: 'No se pudo procesar el pedido');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsafeItems = _unsafeCartItems;
    final hasUnsafeItems = unsafeItems.isNotEmpty;
    final lines = _lines;
    final deliveryText = _formatDeliveryDate();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _editableCart);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTheme.lightAppBar(
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi carrito'),
              if (deliveryText.isNotEmpty)
                Text(
                  'Entrega: $deliveryText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _editableCart),
          ),
        ),
        body: ResponsiveCenter(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasUnsafeItems)
                      _buildAllergenWarningBanner(unsafeItems),
                    Expanded(
                      child: lines.isEmpty
                          ? const Center(
                              child: Text(
                                'Tu carrito está vacío',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF8A8686),
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                ...lines.map((line) {
                                  final dish = line.key;
                                  return _buildCartItemCard(
                                    dish,
                                    line.value,
                                    unsafeItems.contains(dish),
                                    CartRules.canRemoveLine(lines.length),
                                  );
                                }),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Método de pago',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink900,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _buildPaymentOption(
                                  'Billetera Digital',
                                  Icons.account_balance_wallet_outlined,
                                  true,
                                ),
                              ],
                            ),
                    ),
                    _buildBottomBar(hasUnsafeItems),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllergenWarningBanner(List<MenuDish> unsafeItems) {
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este estudiante';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.danger500),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quita estos productos antes de pagar ($childLabel tiene alergias):',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ...unsafeItems.map(
                  (dish) => Text(
                    '• ${dish.name}',
                    style: const TextStyle(
                      color: AppColors.danger700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
    MenuDish dish,
    int quantity,
    bool isUnsafe,
    bool canRemove,
  ) {
    return CartLineTile(
      name: dish.name,
      unitPrice: dish.price,
      quantity: quantity,
      isUnsafe: isUnsafe,
      onIncrement: () => _updateQuantity(dish.id, 1),
      onDecrement: () => _updateQuantity(dish.id, -1),
      onRemove: canRemove ? () => _removeLine(dish.id) : null,
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.secondary500 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.secondary50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected
                ? AppColors.secondary500
                : const Color(0xFF8A8686),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool hasUnsafeItems) {
    final bool isEmpty = _editableCart.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.ink50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.childBalance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo disponible',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '\$${widget.childBalance!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.childBalance! < _total
                          ? AppColors.danger500
                          : AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: hasUnsafeItems
                  ? 'Revisa los alérgenos'
                  : (isEmpty
                        ? 'Carrito vacío'
                        : 'Pagar \$${_total.toStringAsFixed(2)}'),
              onPressed: (_isLoading || isEmpty || hasUnsafeItems)
                  ? null
                  : _handlePayment,
            ),
          ),
        ],
      ),
    );
  }
}
