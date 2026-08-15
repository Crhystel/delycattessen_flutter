import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import 'payphone_webview_screen.dart';

class ChildOption {
  final int walletId;
  final String name;
  final double currentBalance;

  ChildOption({
    required this.walletId,
    required this.name,
    required this.currentBalance,
  });
}

class WalletRechargeScreen extends StatefulWidget {
  final List<ChildOption> children;
  final int initialWalletId;

  const WalletRechargeScreen({
    super.key,
    required this.children,
    required this.initialWalletId,
  });

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();

  late ChildOption _selectedChild;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<double> _quickAmounts = [5.00, 10.00, 15.00];

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.children.firstWhere(
      (c) => c.walletId == widget.initialWalletId,
      orElse: () => widget.children.first,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    setState(() => _amountController.text = amount.toStringAsFixed(2));
  }

  Future<void> _submitRecharge() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Ingresa un monto válido.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _walletService.recharge(
        RechargeRequest(walletId: _selectedChild.walletId, amount: amount),
      );

      if (!mounted) return;

      if (response.isProcessingAsync) {
        _showProcessingDialog();
      } else {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                PayphoneWebViewScreen(paymentUrl: response.paymentUrl!),
          ),
        );
        if (result == true) _showSuccessAndPop();
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.secondary500),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Procesando tu recarga…',
                style: GoogleFonts.nunito(fontSize: 15, color: AppColors.ink900),
              ),
            ),
          ],
        ),
      ),
    );
    _pollTransactionStatus();
  }

  Future<void> _pollTransactionStatus() async {
    for (var i = 0; i < 7; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final transactions = await _walletService.getTransactions(
          _selectedChild.walletId,
        );
        final latest = transactions.isNotEmpty ? transactions.first : null;
        if (latest != null && latest.status != 'pending') {
          if (!mounted) return;
          Navigator.of(context).pop();
          if (latest.status == 'success') {
            _showSuccessAndPop();
          } else {
            setState(
              () =>
                  _errorMessage = 'La recarga fue rechazada. Intenta de nuevo.',
            );
          }
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      Navigator.of(context).pop();
      setState(
        () => _errorMessage =
            'La recarga está tardando más de lo normal. Revisa el historial en unos minutos.',
      );
    }
  }

  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successBg,
        content: Text(
          '¡Recarga exitosa!',
          style: GoogleFonts.nunito(
            color: AppColors.success700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    Navigator.of(context).pop(true);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona a quién recargar',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChildSelector(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Monto a recargar',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAmountField(),
                    const SizedBox(height: 14),
                    _buildQuickAmountChips(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(),
                    ],
                    const SizedBox(height: 28),
                    _buildRechargeButton(),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Billetera Digital',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final child = widget.children[index];
          final isSelected = child.walletId == _selectedChild.walletId;
          return GestureDetector(
            onTap: () => setState(() => _selectedChild = child),
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary500
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.ink50,
                    child: Icon(Icons.person, color: AppColors.secondary500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    child.name,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.ink900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal700,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Saldo Actual de ${_selectedChild.name}',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${_selectedChild.currentBalance.toStringAsFixed(2)}',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink900,
      ),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: GoogleFonts.nunito(
          fontSize: 20,
          color: AppColors.ink900.withValues(alpha: 0.4),
        ),
        hintText: '0.00',
        filled: true,
        fillColor: AppColors.ink50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    return Wrap(
      spacing: 10,
      children: _quickAmounts.map((amount) {
        return GestureDetector(
          onTap: () => _setQuickAmount(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brand500),
            ),
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brand700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _errorMessage!,
        style: GoogleFonts.nunito(fontSize: 13, color: AppColors.danger700),
      ),
    );
  }

  Widget _buildRechargeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitRecharge,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_outline, size: 18, color: Colors.white),
        label: Text(
          'Recargar saldo seguro',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
