import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import 'payphone_webview_screen.dart';
import 'recharge_card_form_screen.dart';
import '../../../core/widgets/app_notification_dialog.dart';

class ChildOption {
  final int walletId;
  final String name;
  final double currentBalance;
  final String? profilePictureUrl;

  ChildOption({
    required this.walletId,
    required this.name,
    required this.currentBalance,
    this.profilePictureUrl,
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
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();

  late ChildOption _selectedChild;
  String? _errorMessage;
  bool _isSubmitting = false;

  static const List<double> _quickAmounts = [5.00, 10.00, 15.00];
  static const double _gatewayThreshold = 5.0;

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

  Future<void> _proceedToRecharge() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Ingresa un monto válido.');
      return;
    }
    setState(() => _errorMessage = null);

    if (amount < _gatewayThreshold) {
      await _rechargeViaPayphone(amount);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RechargeCardFormScreen(
            walletId: _selectedChild.walletId,
            childName: _selectedChild.name,
            amount: amount,
          ),
        ),
      );
    }
  }

  Future<void> _rechargeViaPayphone(double amount) async {
    setState(() => _isSubmitting = true);
    try {
      final response = await _walletService.recharge(
        RechargeRequest(walletId: _selectedChild.walletId, amount: amount),
      );
      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              PayphoneWebViewScreen(paymentUrl: response.paymentUrl!),
        ),
      );
      if (result == true && mounted) {
        await AppNotificationDialog.show(
          context,
          type: NotificationType.success,
          title: '¡Recarga exitosa!',
          message: 'El saldo se acreditó correctamente.',
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const FloatingBubbles(corner: BubbleCorner.topRight),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Monto a recargar',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAmountField(),
                        const SizedBox(height: 14),
                        _buildQuickAmountChips(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.danger700,
                            ),
                          ),
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
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.brand500,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              IconButton(
                icon: const Icon(Icons.attach_money, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.children.map((child) {
        final isSelected = child.walletId == _selectedChild.walletId;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => setState(() => _selectedChild = child),
            child: Container(
              width: 88,
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.ink50,
                    backgroundImage: child.profilePictureUrl != null
                        ? NetworkImage(child.profilePictureUrl!)
                        : null,
                    child: child.profilePictureUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.secondary500,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    child.name,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.ink900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal500,
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
      textAlign: TextAlign.center,
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
      alignment: WrapAlignment.center,
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

  Widget _buildRechargeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _proceedToRecharge,
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
