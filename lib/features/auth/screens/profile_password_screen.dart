import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
import '../widgets/password_requirements.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
            LabeledTextField(
              label: 'Nueva contraseña',
              controller: _newPassword,
              hint: 'Crea una contraseña segura',
              isPassword: true,
              bottomPadding: 0,
            ),
            ListenableBuilder(
              listenable: _newPassword,
              builder: (context, _) =>
                  PasswordRequirements(password: _newPassword.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Confirmar nueva contraseña',
              controller: _confirmPassword,
              hint: 'Repite la nueva contraseña',
              isPassword: true,
              bottomPadding: 0,
            ),
            ListenableBuilder(
              listenable: Listenable.merge([_newPassword, _confirmPassword]),
              builder: (context, _) {
                final mismatch =
                    _confirmPassword.text.isNotEmpty &&
                    _confirmPassword.text != _newPassword.text;
                if (!mismatch) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Las contraseñas no coinciden',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger700,
                    ),
                  ),
                );
              },
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
