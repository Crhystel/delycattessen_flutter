import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'app_notification_dialog.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink900),
        title: Text(
          widget.isCreating ? 'Crea tu PIN de pago' : 'Confirma tu pago',
          style: GoogleFonts.nunito(
            color: AppColors.ink900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isCreating
                  ? 'Crea un PIN de 4 dígitos para confirmar tus recargas de saldo de forma segura.'
                  : 'Ingresa tu PIN de 4 dígitos para confirmar esta recarga.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.ink900.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildPinField(
              _pinController,
              widget.isCreating ? 'Nuevo PIN' : 'PIN',
            ),
            if (widget.isCreating) ...[
              const SizedBox(height: 16),
              _buildPinField(_confirmController, 'Confirma tu PIN'),
            ],
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
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
                        'Confirmar',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
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
      style: GoogleFonts.nunito(
        fontSize: 24,
        letterSpacing: 12,
        color: AppColors.ink900,
      ),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        filled: true,
        fillColor: AppColors.ink50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
