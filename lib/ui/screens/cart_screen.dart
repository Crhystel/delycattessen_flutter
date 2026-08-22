import 'package:flutter/material.dart';
import '../../data/models/menu_models.dart';
import '../../data/services/menu_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_header_shape.dart';

class CartScreen extends StatefulWidget {
  final int studentId;
  final Map<int, int> cart;
  final List<MenuItem> menuItems;

  const CartScreen({Key? key, required this.studentId, required this.cart, required this.menuItems}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = false;
  String _paymentMethod = 'Billetera Digital';

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
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryPurple,
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            const Text('¡Pago Exitoso!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tu pedido ha sido registrado', style: TextStyle(color: AppColors.textGray)),
            const SizedBox(height: 20),
            Text(
              '-\$${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
            ),
            const SizedBox(height: 8),
            const Text('Saldo restante: \$1.50', style: TextStyle(color: AppColors.primaryBlue)), // Placeholder
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, true); // go back to menu, passing true to clear cart
                },
                child: const Text('Volver al inicio', style: TextStyle(color: AppColors.primaryPurple, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Mi carrito',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...widget.cart.entries.map((e) {
                        final item = widget.menuItems.firstWhere((i) => i.id == e.key);
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
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.fastfood, color: AppColors.textGray),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, size: 16, color: AppColors.textGray),
                                    const SizedBox(width: 8),
                                    Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.add, size: 16, color: AppColors.textGray),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      const Text('Método de pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray)),
                      const SizedBox(height: 12),
                      _buildPaymentOption('Billetera Digital', Icons.account_balance_wallet, true),
                      const SizedBox(height: 8),
                      _buildPaymentOption('Efectivo', Icons.money, false),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
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
        border: Border.all(color: isSelected ? AppColors.primaryPurple : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.primaryPurple : AppColors.textGray,
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _handlePayment,
              child: const Text('Ir a pagar', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
