import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/password_check.dart';
import '../widgets/profile_new_password_fields.dart';

/// Password change from the profile: current, new (with the live requirements
/// guide) and confirmation, in the form style of the app. The forced change
/// after the first login keeps its own screen (`ChangePasswordScreen`); both
/// share the checks through `checkPasswordChange`.
class ProfilePasswordScreen extends StatefulWidget {
  final AuthService? authService;

  const ProfilePasswordScreen({super.key, this.authService});

  @override
  State<ProfilePasswordScreen> createState() => _ProfilePasswordScreenState();
}

class _ProfilePasswordScreenState extends State<ProfilePasswordScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final issue = checkPasswordChange(
      current: _currentPassword.text,
      password: _newPassword.text,
      confirmation: _confirmPassword.text,
    );
    if (issue != null) {
      showWarningSnackBar(issue.message, title: issue.title);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _authService.changePassword(
        ChangePasswordRequest(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
          confirmPassword: _confirmPassword.text,
        ),
      );
      if (!mounted) return;
      showSuccessSnackBar(
        'Tu contraseña se actualizó correctamente.',
        title: 'Contraseña actualizada',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        errorMessageOf(e),
        title: 'No se pudo actualizar la contraseña',
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Contraseña',
      children: [
        FormSectionCard(
          design: true,
          title: 'Cambiar contraseña',
          subtitle: 'Escribe tu contraseña actual y la nueva.',
          children: [
            LabeledTextField(
              label: 'Contraseña actual',
              controller: _currentPassword,
              hint: 'Escribe tu contraseña actual',
              isPassword: true,
            ),
            ProfileNewPasswordFields(
              passwordController: _newPassword,
              confirmController: _confirmPassword,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          design: true,
          shadow: true,
          label: 'Guardar contraseña',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
