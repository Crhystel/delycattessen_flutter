import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/password_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/password_requirements.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';

enum _ResetStep { requestCode, setNewPassword, done }

/// Password recovery by email (HU-02.4): the backend emails a 6-digit code
/// valid for 15 minutes, and the user sets a new password with it.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with NotificationMixin {
  static const int _codeLength = 6;

  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetStep _step = _ResetStep.requestCode;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // El backend busca el correo tal cual, y los correos se registran en minúsculas.
  String get _email => _emailController.text.trim().toLowerCase();

  bool get _passwordsMismatch =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _newPasswordController.text != _confirmPasswordController.text;

  Future<bool> _sendCode() async {
    try {
      await _authService.requestPasswordReset(
        PasswordResetRequest(email: _email),
      );
      return true;
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          title: 'No se pudo enviar el código',
        );
      }
      return false;
    }
  }

  Future<void> _handleRequestCode() async {
    if (!_email.contains('@')) {
      showWarningSnackBar(
        'Ingresa el correo con el que te registraste.',
        title: 'Correo requerido',
      );
      return;
    }

    setState(() => _isLoading = true);
    final sent = await _sendCode();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (sent) _step = _ResetStep.setNewPassword;
    });
  }

  Future<void> _handleResendCode() async {
    setState(() => _isResending = true);
    final sent = await _sendCode();
    if (!mounted) return;
    setState(() => _isResending = false);
    if (sent) {
      _codeController.clear();
      showInfoSnackBar(
        'Te enviamos un código nuevo. El anterior ya no sirve.',
        title: 'Código reenviado',
      );
    }
  }

  Future<void> _handleConfirmReset() async {
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (code.length != _codeLength) {
      showWarningSnackBar(
        'El código de verificación tiene $_codeLength dígitos.',
        title: 'Código incompleto',
      );
      return;
    }
    if (!PasswordPolicy.isValid(newPassword)) {
      showWarningSnackBar(
        'A tu contraseña le falta:\n${PasswordPolicy.missingSummary(newPassword)}',
        title: 'Contraseña insegura',
      );
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      showWarningSnackBar(
        'Verifica que ambas contraseñas sean iguales.',
        title: 'Las contraseñas no coinciden',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.confirmPasswordReset(
        PasswordResetConfirm(
          email: _email,
          code: code,
          newPassword: newPassword,
          confirmPassword: _confirmPasswordController.text,
        ),
      );
      if (!mounted) return;
      setState(() => _step = _ResetStep.done);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo restablecer la contraseña',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _backToEmailStep() {
    setState(() {
      _step = _ResetStep.requestCode;
      _codeController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _ResetStep.requestCode:
        return _buildRequestCodeStep();
      case _ResetStep.setNewPassword:
        return _buildSetNewPasswordStep();
      case _ResetStep.done:
        return _buildDoneStep();
    }
  }

  Widget _buildRequestCodeStep() {
    return AuthFormLayout(
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
      icon: Icons.lock_reset,
      title: 'Recuperar contraseña',
      subtitle: 'Ingresa tu correo y te enviaremos un código de verificación',
      footer: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          // Los estudiantes no tienen correo: su cuenta la gestiona el representante.
          'Si eres estudiante, pide a tu representante que te ayude con tu contraseña.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink900.withValues(alpha: 0.6),
          ),
        ),
        _buildBackToLoginButton(),
      ],
      children: [
        AuthTextField(
          controller: _emailController,
          hint: 'Correo electrónico',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Enviar código',
          isLoading: _isLoading,
          onPressed: _handleRequestCode,
        ),
      ],
    );
  }

  Widget _buildSetNewPasswordStep() {
    return AuthFormLayout(
      showBackButton: true,
      onBack: _backToEmailStep,
      icon: Icons.mark_email_read_outlined,
      title: 'Revisa tu correo',
      subtitle:
          'Escribe el código de $_codeLength dígitos que enviamos a $_email. Vence en 15 minutos.',
      footer: [
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: _isResending || _isLoading ? null : _handleResendCode,
          child: Text(
            _isResending
                ? 'Enviando código...'
                : '¿No te llegó? Reenviar código',
            style: const TextStyle(
              color: AppColors.teal700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _buildBackToLoginButton(),
      ],
      children: [
        AuthTextField(
          controller: _codeController,
          hint: 'Código de $_codeLength dígitos',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_codeLength),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _newPasswordController,
          hint: 'Nueva contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirements(password: _newPasswordController.text),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _confirmPasswordController,
          hint: 'Confirmar nueva contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          onChanged: (_) => setState(() {}),
        ),
        if (_passwordsMismatch)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Las contraseñas no coinciden',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Restablecer contraseña',
          isLoading: _isLoading,
          onPressed: _handleConfirmReset,
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return AuthFormLayout(
      icon: Icons.check_circle_outline,
      title: 'Contraseña actualizada',
      subtitle: 'Ya puedes iniciar sesión con tu nueva contraseña.',
      children: [
        PrimaryButton(
          label: 'Ir a iniciar sesión',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        'Volver al inicio de sesión',
        style: TextStyle(color: AppColors.teal700, fontWeight: FontWeight.w700),
      ),
    );
  }
}
