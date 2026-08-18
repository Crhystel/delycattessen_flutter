import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import 'payphone_webview_screen.dart';

class RechargeCardFormScreen extends StatefulWidget {
  final int walletId;
  final String childName;
  final double amount;

  const RechargeCardFormScreen({
    super.key,
    required this.walletId,
    required this.childName,
    required this.amount,
  });

  @override
  State<RechargeCardFormScreen> createState() => _RechargeCardFormScreenState();
}

class _RechargeCardFormScreenState extends State<RechargeCardFormScreen> {
  final _walletService = WalletService();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expirationController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _confirmPayment() async {
    if (_cardNumberController.text.replaceAll(' ', '').length < 16 ||
        _holderNameController.text.isEmpty ||
        _expirationController.text.length < 5 ||
        _cvvController.text.length < 3) {
      setState(
        () => _errorMessage =
            'Completa todos los campos de la tarjeta correctamente.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _walletService.recharge(
        RechargeRequest(walletId: widget.walletId, amount: widget.amount),
      );

      if (!mounted) return;

      if (response.isProcessingAsync) {
        await _pollUntilResolved();
      } else {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                PayphoneWebViewScreen(paymentUrl: response.paymentUrl!),
          ),
        );
        if (result == true && mounted) _showSuccess();
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pollUntilResolved() async {
    for (var i = 0; i < 7; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final transactions = await _walletService.getTransactions(
          widget.walletId,
        );
        final latest = transactions.isNotEmpty ? transactions.first : null;
        if (latest != null && latest.status != 'pending') {
          if (!mounted) return;
          if (latest.status == 'success') {
            _showSuccess();
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
      setState(
        () => _errorMessage =
            'La recarga está tardando más de lo normal. Revisa el historial en unos minutos.',
      );
    }
  }

  void _showSuccess() {
    AppNotificationDialog.show(
      context,
      type: NotificationType.success,
      title: '¡Pago Exitoso!',
      message: 'Tu recarga ha sido registrada',
      highlightValue: '-\$${widget.amount.toStringAsFixed(2)}',
      primaryButtonLabel: 'Volver al inicio',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink900),
        title: Text(
          'Recarga segura',
          style: GoogleFonts.nunito(
            color: AppColors.ink900,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardPreview(),
            const SizedBox(height: 16),
            _buildUserSummaryCard(),
            const SizedBox(height: 20),
            _buildLabel('NÚMERO DE TARJETA'),
            _buildField(
              _cardNumberController,
              '0000 0000 0000 0000',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _buildLabel('NOMBRE DEL TITULAR'),
            _buildField(
              _holderNameController,
              'Ingrese el nombre',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('VENCIMIENTO'),
                      _buildField(
                        _expirationController,
                        'MM/AA',
                        keyboardType: TextInputType.datetime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('CVV'),
                      _buildField(
                        _cvvController,
                        '•••',
                        keyboardType: TextInputType.number,
                        obscure: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: GoogleFonts.nunito(
                  color: AppColors.danger700,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirmar pago',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary700, AppColors.teal500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.brand500,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            _cardNumberController.text.isEmpty
                ? '**** **** **** 1234'
                : _cardNumberController.text,
            style: GoogleFonts.nunito(
              fontSize: 17,
              letterSpacing: 2,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Titular',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _holderNameController.text.isEmpty
                        ? 'NOMBRE APELLIDO'
                        : _holderNameController.text.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Vence',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _expirationController.text.isEmpty
                        ? '12/28'
                        : _expirationController.text,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.ink50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.secondary500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.childName,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Monto a\nrecargar',
                textAlign: TextAlign.right,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: AppColors.ink900.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '\$${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondary500,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.nunito(color: AppColors.ink900),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          color: AppColors.ink900.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.secondary500, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary500,
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary500,
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary700,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
