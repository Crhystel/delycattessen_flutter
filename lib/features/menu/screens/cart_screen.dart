import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/custom_header_shape.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';

class CartScreen extends StatefulWidget {
  final int studentId;
  final Map<int, int> cart;
  final List<MenuItem> menuItems;

  const CartScreen({
    Key? key,
    required this.studentId,
    required this.cart,
    required this.menuItems,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = false;

  double get _total {
    return widget.cart.entries.fold(0, (sum, entry) {
      final item = widget.menuItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.price * entry.value);
    });
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final orderItems = widget.cart.entries
          .map((e) => PreOrderItem(menuItemId: e.key, quantity: e.value))
          .toList();
      final preOrder = PreOrder(studentId: widget.studentId, items: orderItems);

      await _menuService.createPreOrder(preOrder);

      if (!mounted) return;
      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'No se pudo procesar el pedido',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await AppNotificationDialog.show(
      context,
      type: NotificationType.success,
      title: '¡Pago Exitoso!',
      message: 'Tu pedido ha sido registrado',
      highlightValue: '-\$${_total.toStringAsFixed(2)}',
      primaryButtonLabel: 'Volver al inicio',
      onPrimaryPressed: () {
        Navigator.of(context).pop(); // cierra el diálogo
        Navigator.of(
          context,
        ).pop(true); // vuelve al menú, avisando que limpie el carrito
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...widget.cart.entries.map((e) {
                        final item = widget.menuItems.firstWhere(
                          (i) => i.id == e.key,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.ink50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Color(0xFF8A8686),
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
                                      '${e.value}',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Color(0xFF8A8686),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                _buildBottomBar(),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.ink50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                backgroundColor: AppColors.secondary500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _handlePayment,
              child: Text(
                'Ir a pagar',
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
