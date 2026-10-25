import 'package:flutter/material.dart';

import '../utils/password_policy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../widgets/password_requirements.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/auth_routing.dart';
import '../../../core/utils/error_message.dart';

class ChangePasswordScreen extends StatefulWidget {
  final MeResponse me;
  final String usernameFallback;

  /// Opened from the profile: on success it goes back instead of routing to
  /// the home screen (used by the forced change after the first login).
  final bool popOnSuccess;

  const ChangePasswordScreen({
    super.key,
    required this.me,
    required this.usernameFallback,
    this.popOnSuccess = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with NotificationMixin {
  final _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Repinta la guía de requisitos mientras el usuario escribe.
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() => setState(() {});

  bool get _meetsPasswordPolicy => PasswordPolicy.rules.every(
    (rule) => rule.test(_newPasswordController.text),
  );

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      showWarningSnackBar(
        'Completa todos los campos.',
        title: 'Datos incompletos',
      );
      return;
    }
    if (!_meetsPasswordPolicy) {
      showWarningSnackBar(
        'La nueva contraseña no cumple los requisitos de seguridad.',
        title: 'Contraseña insegura',
      );
      return;
    }
    if (newPassword != confirm) {
      showWarningSnackBar(
        'Las contraseñas nuevas no coinciden.',
        title: 'No coinciden',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.changePassword(
        ChangePasswordRequest(
          currentPassword: current,
          newPassword: newPassword,
          confirmPassword: confirm,
        ),
      );
      if (!mounted) return;
      if (widget.popOnSuccess) {
        showSuccessSnackBar(
          'Tu contraseña se actualizó correctamente.',
          title: 'Contraseña actualizada',
        );
        Navigator.of(context).pop();
        return;
      }
      routeAfterAuth(
        context,
        widget.me,
        usernameFallback: widget.usernameFallback,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        errorMessageOf(e),
        title: 'No se pudo actualizar la contraseña',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromProfile = widget.popOnSuccess;
    return PopScope(
      // The forced change after the first login cannot be skipped.
      canPop: fromProfile,
      child: AuthFormLayout(
        icon: Icons.lock_reset,
        title: 'Cambia tu contraseña',
        subtitle: fromProfile
            ? 'Escribe tu contraseña actual y la nueva.'
            : 'Por seguridad, debes establecer una contraseña propia antes de continuar.',
        showBackButton: fromProfile,
        children: [
          AuthTextField(
            controller: _currentPasswordController,
            hint: fromProfile ? 'Contraseña actual' : 'Contraseña temporal',
            icon: Icons.lock_clock_outlined,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _newPasswordController,
            hint: 'Nueva contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          PasswordRequirements(password: _newPasswordController.text),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _confirmPasswordController,
            hint: 'Confirmar nueva contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Guardar y continuar',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
