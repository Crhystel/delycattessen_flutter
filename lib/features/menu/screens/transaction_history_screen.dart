import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../wallet/models/wallet_models.dart';
import '../../wallet/services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int walletId;
  final String childName;

  const TransactionHistoryScreen({
    super.key,
    required this.walletId,
    required this.childName,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _walletService = WalletService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactions = await _walletService.getTransactions(
        widget.walletId,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTransactions,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary500,
                        ),
                      )
                    : _errorMessage != null
                    ? _buildMessage(_errorMessage!, isError: true)
                    : _transactions.isEmpty
                    ? _buildMessage('Aún no hay movimientos registrados.')
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          16 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildTransactionRow(_transactions[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(color: AppColors.secondary500),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Historial de consumo',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: isError
                ? AppColors.danger700
                : AppColors.ink900.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionModel transaction) {
    final isRecharge = transaction.type == 'recharge';
    final isFailed = transaction.status == 'failed';

    return GestureDetector(
      onTap: () => _showTransactionDetail(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isRecharge ? AppColors.successBg : AppColors.brand50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRecharge ? Icons.add : Icons.restaurant,
                color: isRecharge ? AppColors.success700 : AppColors.brand700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayName,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.time,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isFailed
                  ? 'Fallida'
                  : '${isRecharge ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isFailed
                    ? AppColors.ink900.withValues(alpha: 0.4)
                    : (isRecharge ? AppColors.success700 : AppColors.danger700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
    final isRecharge = transaction.type == 'recharge';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.time,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.ink900.withValues(alpha: 0.5),
                  ),
                ),
                const Divider(height: 28),
                if (isRecharge) ...[
                  _buildDetailRow(
                    'Método',
                    transaction.gateway.isNotEmpty
                        ? transaction.gateway
                        : 'No especificado',
                  ),
                  _buildDetailRow(
                    'Estado',
                    transaction.status == 'failed' ? 'Fallida' : 'Exitosa',
                  ),
                ] else if (transaction.items.isNotEmpty) ...[
                  ...transaction.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.menuItemName}',
                              style: GoogleFonts.nunito(fontSize: 14),
                            ),
                          ),
                          Text(
                            '\$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ] else
                  Text(
                    'No hay detalle disponible para este movimiento.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isRecharge ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isRecharge
                            ? AppColors.success700
                            : AppColors.danger700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
