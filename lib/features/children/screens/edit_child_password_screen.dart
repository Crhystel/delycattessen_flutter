import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/password_check.dart';
import '../../auth/widgets/profile_new_password_fields.dart';

/// The parent sets a new password for a child. They confirm with their own
/// password (the child's current one is not theirs to know); the backend closes
/// the child's sessions and e-mails the parent a notice without the password.
/// A wrong confirmation never signs the parent out.
class EditChildPasswordScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  const EditChildPasswordScreen({
    super.key,
    required this.child,
    this.authService,
  });

  @override
  State<EditChildPasswordScreen> createState() =>
      _EditChildPasswordScreenState();
}

class _EditChildPasswordScreenState extends State<EditChildPasswordScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _parentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _parentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final issue = checkPasswordChange(
      current: _parentPassword.text,
      password: _newPassword.text,
      confirmation: _confirmPassword.text,
      currentMessage: 'Ingresa tu contraseña para confirmar el cambio.',
    );
    if (issue != null) {
      showWarningSnackBar(issue.message, title: issue.title);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _authService.changeChildPassword(
        widget.child.id,
        ChildPasswordChange(
          parentPassword: _parentPassword.text,
          newPassword: _newPassword.text,
          confirmPassword: _confirmPassword.text,
        ),
      );
      if (!mounted) return;
      showSuccessSnackBar(
        'La contraseña de ${widget.child.firstName} se actualizó. Te '
        'avisamos a tu correo.',
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
          title: 'Contraseña de ${widget.child.firstName}',
          subtitle:
              'Escribe la nueva contraseña de tu hijo/a y confirma con la '
              'tuya. Te avisaremos por correo.',
          children: [
            LabeledTextField(
              label: 'Tu contraseña',
              controller: _parentPassword,
              hint: 'Escribe tu contraseña para confirmar',
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
