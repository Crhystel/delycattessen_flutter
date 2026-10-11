import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';

class CartScreen extends StatefulWidget {
  final int studentId;
  final Map<int, int> cart;
  final List<MenuItem> menuItems;
  final Set<int> childAllergenIds;
  final String childName;
  final double? childBalance;

  const CartScreen({
    super.key,
    required this.studentId,
    required this.cart,
    required this.menuItems,
    this.childAllergenIds = const {},
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

  void _updateQuantity(int itemId, int delta) {
    setState(() {
      final current = _editableCart[itemId] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _editableCart.remove(itemId);
      } else {
        _editableCart[itemId] = next;
      }
    });
  }

  /// Ítems del carrito resueltos contra el menú.
  List<MapEntry<MenuItem, int>> get _lines {
    final lines = <MapEntry<MenuItem, int>>[];
    for (final entry in _editableCart.entries) {
      final matches = widget.menuItems.where((i) => i.id == entry.key);
      if (matches.isNotEmpty) lines.add(MapEntry(matches.first, entry.value));
    }
    return lines;
  }

  double get _total {
    return _lines.fold(0, (sum, line) => sum + (line.key.price * line.value));
  }

  /// Ítems del carrito que contienen algún alérgeno registrado para el hijo
  /// seleccionado. Re-verificación de seguridad justo antes de pagar: el
  /// carrito pudo haberse llenado antes de un cambio de hijo o de una
  /// actualización de alergias, así que no basta con el filtrado ya hecho
  /// en MenuScreen.
  List<MenuItem> get _unsafeCartItems {
    if (widget.childAllergenIds.isEmpty) return [];
    return _lines
        .map((line) => line.key)
        .where(
          (item) =>
              item.allergens.any((a) => widget.childAllergenIds.contains(a.id)),
        )
        .toList();
  }

  Set<String> _allergenNamesFor(MenuItem item) {
    return item.allergens
        .where((a) => widget.childAllergenIds.contains(a.id))
        .map((a) => a.name)
        .toSet();
  }

  void _showBlockedDialog() {
    final unsafe = _unsafeCartItems;
    final itemsList = unsafe.map((i) => i.name).join(', ');
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este hijo';

    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'No se puede procesar el pedido',
      message:
          'El carrito contiene productos no seguros para $childLabel: '
          '$itemsList. Vuelve al menú y quítalos antes de continuar.',
    );
  }

  Future<void> _handlePayment() async {
    if (_unsafeCartItems.isNotEmpty) {
      _showBlockedDialog();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orderItems = _editableCart.entries
          .map((e) => PreOrderItem(menuItemId: e.key, quantity: e.value))
          .toList();
      final preOrder = PreOrder(studentId: widget.studentId, items: orderItems);

      await _menuService.createPreOrder(preOrder);

      if (!mounted) return;
      _showSuccessNotification();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo procesar el pedido',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessNotification() {
    showSuccessSnackBar(
      'Tu pedido ha sido registrado (-\$${_total.toStringAsFixed(2)})',
      title: '¡Pago Exitoso!',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final unsafeItems = _unsafeCartItems;
    final hasUnsafeItems = unsafeItems.isNotEmpty;
    final lines = _lines;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi carrito'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasUnsafeItems) _buildAllergenWarningBanner(unsafeItems),
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
                              final item = line.key;
                              return _buildCartItemCard(
                                item,
                                line.value,
                                unsafeItems.contains(item),
                              );
                            }),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Método de pago',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  child: CircularProgressIndicator(color: AppColors.secondary500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Único aviso de alérgenos de la pantalla: lista qué producto contiene qué.
  Widget _buildAllergenWarningBanner(List<MenuItem> unsafeItems) {
    final textTheme = Theme.of(context).textTheme;
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este hijo';
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
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger700,
                  ),
                ),
                const SizedBox(height: 4),
                ...unsafeItems.map(
                  (item) => Text(
                    '• ${item.name}: ${_allergenNamesFor(item).join(", ")}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger700,
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

  Widget _buildCartItemCard(MenuItem item, int quantity, bool isUnsafe) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnsafe ? AppColors.dangerBg : Colors.white,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isUnsafe ? AppColors.danger500 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.ink50,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(Icons.fastfood, color: AppColors.secondary500),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    quantity == 1 ? Icons.delete_outline : Icons.remove,
                    size: 18,
                    color: const Color(0xFF8A8686),
                  ),
                  onPressed: () => _updateQuantity(item.id, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF8A8686),
                  ),
                  onPressed: () => _updateQuantity(item.id, 1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.secondary500 : const Color(0xFFE5E7EB),
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
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
    final textTheme = Theme.of(context).textTheme;
    final total = _total;
    final isEmpty = _editableCart.isEmpty;
    final insufficient =
        widget.childBalance != null && widget.childBalance! < total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.childBalance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.childName.isNotEmpty
                        ? 'Saldo de ${widget.childName}'
                        : 'Saldo disponible',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '\$${widget.childBalance!.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: insufficient
                          ? AppColors.danger500
                          : AppColors.success700,
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
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (insufficient)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'El saldo no alcanza. Recarga en la pestaña Billetera.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.danger500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (hasUnsafeItems || isEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink900.withValues(alpha: 0.2),
                  foregroundColor: AppColors.ink900,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.fullAll,
                  ),
                ),
                onPressed: null,
                child: Text(isEmpty ? 'Carrito vacío' : 'Revisa tu carrito'),
              ),
            )
          else
            PrimaryButton(
              label: 'Pagar \$${total.toStringAsFixed(2)}',
              icon: Icons.check_circle_outline,
              isLoading: false,
              onPressed: _isLoading ? null : _handlePayment,
            ),
        ],
      ),
    );
  }
}
