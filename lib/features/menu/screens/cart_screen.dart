import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/custom_header_shape.dart';
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

  double get _total {
    return widget.cart.entries.fold(0, (sum, entry) {
      final item = widget.menuItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.price * entry.value);
    });
  }

  /// Ítems del carrito que contienen algún alérgeno registrado para el hijo
  /// seleccionado. Re-verificación de seguridad justo antes de pagar: el
  /// carrito pudo haberse llenado antes de un cambio de hijo o de una
  /// actualización de alergias, así que no basta con el filtrado ya hecho
  /// en MenuScreen.
  List<MenuItem> get _unsafeCartItems {
    if (widget.childAllergenIds.isEmpty) return [];
    return widget.cart.keys
        .map((id) => widget.menuItems.firstWhere((i) => i.id == id))
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
      final orderItems = widget.cart.entries
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
    final hasUnsafeItems = _unsafeCartItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomHeaderShape(height: 50),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.ink900,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Mi carrito',
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasUnsafeItems) _buildAllergenWarningBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...widget.cart.entries.map((e) {
                        final item = widget.menuItems.firstWhere(
                          (i) => i.id == e.key,
                        );
                        final isUnsafe = _unsafeCartItems.contains(item);
                        return _buildCartItemCard(item, e.value, isUnsafe);
                      }),
                      const SizedBox(height: 24),
                      Text(
                        'Método de pago',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentOption(
                        'Billetera Digital',
                        Icons.account_balance_wallet,
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
    );
  }

  Widget _buildAllergenWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger500),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay productos en tu carrito con alérgenos de '
              '${widget.childName.isNotEmpty ? widget.childName : "este hijo"}. '
              'Quítalos antes de pagar.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(MenuItem item, int quantity, bool isUnsafe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isUnsafe ? AppColors.danger500 : Colors.grey.shade300,
          width: isUnsafe ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isUnsafe ? AppColors.dangerBg : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.ink50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fastfood, color: Color(0xFF8A8686)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.nunito(
                        color: AppColors.brand700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFF8A8686),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add, size: 16, color: Color(0xFF8A8686)),
                  ],
                ),
              ),
            ],
          ),
          if (isUnsafe) ...[
            const SizedBox(height: 8),
            Text(
              '⚠ Contiene: ${_allergenNamesFor(item).join(", ")}',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger500,
              ),
            ),
          ],
        ],
      ),
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
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.ink50),
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
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '\$${widget.childBalance!.toStringAsFixed(2)}',
                    style: GoogleFonts.nunito(
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
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasUnsafeItems
                    ? AppColors.ink900.withValues(alpha: 0.25)
                    : AppColors.secondary500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _handlePayment,
              child: Text(
                hasUnsafeItems ? 'Revisa tu carrito' : 'Ir a pagar',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
