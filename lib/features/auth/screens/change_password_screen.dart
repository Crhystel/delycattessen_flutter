import 'package:flutter/material.dart';

import '../utils/password_check.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../widgets/new_password_fields.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/auth_routing.dart';
import '../../../core/utils/error_message.dart';

/// Forced password change after the first login (temporary password). The
/// regular change lives in the profile (`ProfilePasswordScreen`); both share
/// the same checks through `checkPasswordChange`.
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
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    final issue = checkPasswordChange(
      current: current,
      password: newPassword,
      confirmation: confirm,
    );
    if (issue != null) {
      showWarningSnackBar(issue.message, title: issue.title);
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
        errorMessageOf(e),
        title: 'No se pudo actualizar la contraseña',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The forced change after the first login cannot be skipped.
      canPop: false,
      child: AuthFormLayout(
        icon: Icons.lock_reset,
        title: 'Cambia tu contraseña',
        subtitle:
            'Por seguridad, debes establecer una contraseña propia antes de continuar.',
        showBackButton: false,
        children: [
          AuthTextField(
            controller: _currentPasswordController,
            hint: 'Contraseña temporal',
            icon: Icons.lock_clock_outlined,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.md),
          NewPasswordFields(
            passwordController: _newPasswordController,
            confirmController: _confirmPasswordController,
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
