import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_header_shape.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../../../core/widgets/custom_bottom_nav.dart';

class OrdersScreen extends StatefulWidget {
  final int? studentId;

  const OrdersScreen({super.key, this.studentId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<PreOrderSummary> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await _menuService.getPreOrders(
        studentId: widget.studentId,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusAccent(PreOrderStatus status) {
    switch (status) {
      case PreOrderStatus.pending:
        return AppColors.warning500;
      case PreOrderStatus.delivered:
        return AppColors.success500;
      case PreOrderStatus.canceled:
        return AppColors.danger500;
    }
  }

  Color _statusBackground(PreOrderStatus status) {
    switch (status) {
      case PreOrderStatus.pending:
        return AppColors.warningBg;
      case PreOrderStatus.delivered:
        return AppColors.successBg;
      case PreOrderStatus.canceled:
        return AppColors.dangerBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeaderShape(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.ink900,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Mis pedidos',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        studentId: widget.studentId,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        color: AppColors.secondary500,
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger500.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: AppColors.ink900),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.secondary500,
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Text(
                'Todavía no tienes pedidos.',
                style: GoogleFonts.nunito(
                  color: AppColors.ink900.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(PreOrderSummary order) {
    final accent = _statusAccent(order.status);
    final background = _statusBackground(order.status);
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.studentName,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusDisplay,
                  style: GoogleFonts.nunito(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.ink900.withValues(alpha: 0.5),
            ),
          ),
          const Divider(height: 20),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.menuItemName}',
                      style: GoogleFonts.nunito(fontSize: 13),
                    ),
                  ),
                  Text(
                    '\$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
