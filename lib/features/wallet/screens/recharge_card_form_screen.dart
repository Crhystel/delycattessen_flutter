import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../models/document_type.dart';
import '../services/card_recharge_service.dart';
import '../widgets/kushki_badge.dart';
import '../../../core/utils/error_message.dart';

/// Inserts a space every 4 digits as the user types the card number.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 16; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Inserts a "/" automatically after the 2-digit month (MM/AA).
class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digitsOnly.length > 4
        ? digitsOnly.substring(0, 4)
        : digitsOnly;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

class _RechargeCardFormScreenState extends State<RechargeCardFormScreen>
    with NotificationMixin {
  final _rechargeService = CardRechargeService();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expirationController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();

  DocumentType _documentType = DocumentType.cedula;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final data = CardFormData(
      cardNumber: _cardNumberController.text,
      holderName: _holderNameController.text,
      expiration: _expirationController.text,
      cvv: _cvvController.text,
      phone: _phoneController.text,
      documentNumber: _documentNumberController.text,
      documentType: _documentType,
      acceptedTerms: _acceptedTerms,
    );
    final validationError = data.validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final status = await _rechargeService.recharge(
        walletId: widget.walletId,
        amount: widget.amount,
        data: data,
        isCancelled: () => !mounted,
      );
      if (!mounted) return;
      _showResult(status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = errorMessageOf(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResult(CardRechargeStatus status) {
    switch (status) {
      case CardRechargeStatus.credited:
        _showSuccess();
      case CardRechargeStatus.rejected:
        setState(
          () => _errorMessage = 'La recarga fue rechazada. Intenta de nuevo.',
        );
      case CardRechargeStatus.timedOut:
        setState(
          () => _errorMessage =
              'La recarga está tardando más de lo normal. Revisa el historial en unos minutos.',
        );
      case CardRechargeStatus.submitted:
      case CardRechargeStatus.cancelled:
        break;
    }
  }

  /// Acreditado: devuelve true a la pantalla de recarga, que cierra el flujo.
  void _showSuccess() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTheme.lightAppBar(title: const Text('Recarga segura')),
      body: ResponsiveCenter(
        maxWidth: AppLayout.formMaxWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardPreview(),
              const SizedBox(height: 12),
              const KushkiBadge(),
              const SizedBox(height: 16),
              _buildUserSummaryCard(),
              const SizedBox(height: 20),
              _buildLabel('NÚMERO DE TARJETA'),
              _buildField(
                _cardNumberController,
                '0000 0000 0000 0000',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [_CardNumberFormatter()],
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [_ExpirationDateFormatter()],
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
              const SizedBox(height: 14),
              _buildLabel('CORREO'),
              _buildField(
                _emailController,
                'correo@ejemplo.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildLabel('TELÉFONO'),
              _buildField(
                _phoneController,
                'Ej. 0991234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildLabel('TIPO DE DOCUMENTO'),
              _buildDocumentTypeDropdown(),
              const SizedBox(height: 14),
              _buildLabel('NÚMERO DE DOCUMENTO'),
              _buildField(
                _documentNumberController,
                'Ej. 1712345678',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) =>
                        setState(() => _acceptedTerms = value ?? false),
                    activeColor: AppColors.secondary500,
                  ),
                  Expanded(
                    child: Text(
                      'Acepto los Términos y Condiciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ink900.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.danger700, fontSize: 12),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Confirmar pago',
                icon: Icons.lock_outline,
                isLoading: _isSubmitting,
                onPressed: _confirmPayment,
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          colors: [AppColors.teal700, AppColors.teal500],
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
                ? '**** **** **** ****'
                : _cardNumberController.text,
            style: TextStyle(
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
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    _holderNameController.text.isEmpty
                        ? 'NOMBRE APELLIDO'
                        : _holderNameController.text.toUpperCase(),
                    style: TextStyle(
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
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    _expirationController.text.isEmpty
                        ? '00/00'
                        : _expirationController.text,
                    style: TextStyle(
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
              style: const TextStyle(
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
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.ink900.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '\$${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
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
      style: const TextStyle(
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppColors.ink900),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.secondary500, size: 20)
            : null,
      ),
    );
  }

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<DocumentType>(
      initialValue: _documentType,
      items: DocumentType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(
                type.label,
                style: const TextStyle(fontSize: 14, color: AppColors.ink900),
              ),
            ),
          )
          .toList(),
      onChanged: (value) =>
          setState(() => _documentType = value ?? DocumentType.cedula),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.secondary500,
      ),
      decoration: const InputDecoration(),
    );
  }
}
