import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'primary_button.dart';

/// Reusable PIN screen. In "create" mode, asks the user to type a 4-digit
/// PIN twice (confirmation). In "verify" mode, asks for the existing PIN
/// and checks it against the backend before allowing a payment to proceed.
class PinEntryScreen extends StatefulWidget {
  final bool isCreating;
  final Future<void> Function(String pin)? onCreate;
  final Future<bool> Function(String pin)? onVerify;

  const PinEntryScreen({
    super.key,
    required this.isCreating,
    this.onCreate,
    this.onVerify,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _errorMessage = 'El PIN debe tener 4 dígitos.');
      return;
    }

    if (widget.isCreating) {
      if (pin != _confirmController.text) {
        setState(() => _errorMessage = 'Los PIN no coinciden.');
        return;
      }
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      try {
        await widget.onCreate!(pin);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      try {
        final isValid = await widget.onVerify!(pin);
        if (!mounted) return;
        if (isValid) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _errorMessage = 'PIN incorrecto.');
        }
      } catch (e) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(
        title: Text(
          widget.isCreating ? 'Crea tu PIN de pago' : 'Confirma tu pago',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.teal50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.teal500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.isCreating
                  ? 'Crea un PIN de 4 dígitos para confirmar tus recargas de saldo de forma segura.'
                  : 'Ingresa tu PIN de 4 dígitos para confirmar esta recarga.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildPinField(
              _pinController,
              widget.isCreating ? 'Nuevo PIN' : 'PIN',
            ),
            if (widget.isCreating) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildPinField(_confirmController, 'Confirma tu PIN'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.danger700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Confirmar',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 12,
        color: AppColors.ink900,
      ),
      decoration: InputDecoration(counterText: '', labelText: label),
    );
  }
}
