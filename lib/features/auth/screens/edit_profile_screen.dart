import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';

/// Own profile of a parent or teacher: the four name parts and the email
/// (which is also the login). Pops with the updated [MeResponse] after saving.
/// [canChangePassword] adds the shortcut to change the password (parents).
class EditProfileScreen extends StatefulWidget {
  final MeResponse me;
  final bool canChangePassword;
  final AuthService? authService;

  const EditProfileScreen({
    super.key,
    required this.me,
    this.canChangePassword = false,
    this.authService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final _firstName = TextEditingController(text: widget.me.firstName);
  late final _secondName = TextEditingController(text: widget.me.secondName);
  late final _lastName = TextEditingController(text: widget.me.lastName);
  late final _secondLastName = TextEditingController(
    text: widget.me.secondLastName,
  );
  late final _email = TextEditingController(text: widget.me.email ?? '');
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _secondName,
      _lastName,
      _secondLastName,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final update = ProfileUpdate(
      names: PersonNames(
        firstName: _firstName.text,
        secondName: _secondName.text,
        lastName: _lastName.text,
        secondLastName: _secondLastName.text,
      ),
      email: _email.text,
    );
    final error = update.validate();
    if (error != null) {
      showWarningSnackBar(error, title: 'Revisa tus datos');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateProfile(update);
      if (!mounted) return;
      showSuccessSnackBar(
        'Tus datos se guardaron correctamente.',
        title: 'Perfil actualizado',
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          me: widget.me,
          usernameFallback: widget.me.email ?? '',
          popOnSuccess: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTheme.lightAppBar(title: const Text('Mi perfil')),
      body: ResponsiveCenter(
        maxWidth: AppLayout.formMaxWidth,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledTextField(
                  label: 'Primer nombre',
                  controller: _firstName,
                  hint: 'Ingresa tu primer nombre',
                ),
                LabeledTextField(
                  label: 'Segundo nombre',
                  controller: _secondName,
                  hint: 'Ingresa tu segundo nombre (opcional)',
                ),
                LabeledTextField(
                  label: 'Primer apellido',
                  controller: _lastName,
                  hint: 'Ingresa tu primer apellido',
                ),
                LabeledTextField(
                  label: 'Segundo apellido',
                  controller: _secondLastName,
                  hint: 'Ingresa tu segundo apellido (opcional)',
                ),
                LabeledTextField(
                  label: 'Correo',
                  controller: _email,
                  hint: 'correo@ejemplo.com',
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Guardar cambios',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                if (widget.canChangePassword) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _isSaving ? null : _openChangePassword,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Cambiar contraseña'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
