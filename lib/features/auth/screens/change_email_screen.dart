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
import '../utils/email_check.dart';

/// Changes the email of the signed-in parent or teacher. The email is also
/// the login, so the current password is required (the backend checks it
/// too). Pops with the updated [MeResponse] after saving.
class ChangeEmailScreen extends StatefulWidget {
  final MeResponse me;
  final AuthService? authService;

  const ChangeEmailScreen({super.key, required this.me, this.authService});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _newEmail = TextEditingController();
  final _currentPassword = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newEmail.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final issue = checkEmailChange(
      currentEmail: widget.me.email ?? '',
      newEmail: _newEmail.text,
      currentPassword: _currentPassword.text,
    );
    if (issue != null) {
      showWarningSnackBar(issue.message, title: issue.title);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateProfile(
        ProfileUpdate(
          names: widget.me.names,
          email: _newEmail.text,
          currentPassword: _currentPassword.text,
        ),
      );
      if (!mounted) return;
      showSuccessSnackBar(
        'Tu correo se actualizó. Úsalo la próxima vez que inicies sesión.',
        title: 'Correo actualizado',
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        errorMessageOf(e),
        title: 'No se pudo cambiar el correo',
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.me.email;
    return FormPage(
      title: 'Correo',
      children: [
        FormSectionCard(
          design: true,
          title: 'Nuevo correo',
          subtitle: current == null || current.isEmpty
              ? 'Confirma con tu contraseña actual para cambiar el correo.'
              : 'Tu correo actual es $current. Confirma con tu contraseña '
                    'actual para cambiarlo.',
          children: [
            LabeledTextField(
              label: 'Nuevo correo',
              controller: _newEmail,
              hint: 'correo@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
            LabeledTextField(
              label: 'Contraseña actual',
              controller: _currentPassword,
              hint: 'Escribe tu contraseña actual',
              isPassword: true,
              bottomPadding: 0,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          design: true,
          shadow: true,
          label: 'Guardar correo',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
