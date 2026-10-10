import 'package:flutter/material.dart';

import '../../../core/config/password_policy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/password_requirements.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/auth_routing.dart';

class ChangePasswordScreen extends StatefulWidget {
  final MeResponse me;
  final String usernameFallback;

  const ChangePasswordScreen({
    super.key,
    required this.me,
    required this.usernameFallback,
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
      routeAfterAuth(
        context,
        widget.me,
        usernameFallback: widget.usernameFallback,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo actualizar la contraseña',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthFormLayout(
        icon: Icons.lock_reset,
        title: 'Cambia tu contraseña',
        subtitle:
            'Por seguridad, debes establecer una contraseña propia antes de continuar.',
        children: [
          AuthTextField(
            controller: _currentPasswordController,
            hint: 'Contraseña temporal',
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
