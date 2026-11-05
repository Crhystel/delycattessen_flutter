import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/password_check.dart';
import '../widgets/password_requirements.dart';

/// Own profile of a parent or teacher: the four name parts and the email
/// (which is also the login). Pops with the updated [MeResponse] after saving.
/// [canChangePassword] adds an optional password section to the same form
/// (parents and teachers); it is saved together with the rest of the data.
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
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSaving = false;

  /// Profile already stored when the password step failed: it is returned on
  /// exit so the caller still gets the updated data.
  MeResponse? _savedProfile;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _secondName,
      _lastName,
      _secondLastName,
      _email,
      _currentPassword,
      _newPassword,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _wantsPasswordChange =>
      widget.canChangePassword &&
      (_currentPassword.text.isNotEmpty ||
          _newPassword.text.isNotEmpty ||
          _confirmPassword.text.isNotEmpty);

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

    final changePassword = _wantsPasswordChange;
    if (changePassword) {
      final issue = checkPasswordChange(
        current: _currentPassword.text,
        password: _newPassword.text,
        confirmation: _confirmPassword.text,
      );
      if (issue != null) {
        showWarningSnackBar(issue.message, title: issue.title);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      // Profile first: if it fails nothing else was attempted, and retrying
      // after a password error just saves the same data again.
      _savedProfile = await _authService.updateProfile(update);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo guardar');
      setState(() => _isSaving = false);
      return;
    }

    if (changePassword) {
      try {
        await _authService.changePassword(
          ChangePasswordRequest(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
            confirmPassword: _confirmPassword.text,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showErrorSnackBar(
          'Tus datos se guardaron, pero no se pudo cambiar la contraseña: '
          '${errorMessageOf(e)}',
          title: 'Contraseña sin cambiar',
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    if (!mounted) return;
    showSuccessSnackBar(
      changePassword
          ? 'Tus datos y tu contraseña se guardaron correctamente.'
          : 'Tus datos se guardaron correctamente.',
      title: 'Perfil actualizado',
    );
    Navigator.of(context).pop(_savedProfile);
  }

  String get _displayName {
    final me = _savedProfile ?? widget.me;
    return [
      me.firstName,
      me.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final me = _savedProfile ?? widget.me;
    return PopScope(
      // Leaving after a partial save still hands back the stored profile.
      canPop: _savedProfile == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_savedProfile);
      },
      child: Scaffold(
        backgroundColor: AppColors.ink50,
        appBar: AppTheme.lightAppBar(
          title: const Text('Mi perfil'),
          backgroundColor: AppColors.ink50,
        ),
        body: ResponsiveCenter(
          maxWidth: AppLayout.formMaxWidth,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileSummaryCard(
                    leading: InitialsAvatar(name: _displayName),
                    title: _displayName.isEmpty ? 'Mi perfil' : _displayName,
                    subtitle: me.email,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FormSectionCard(
                    title: 'Datos personales',
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
                        bottomPadding: 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FormSectionCard(
                    title: 'Acceso',
                    subtitle:
                        'Tu correo también es tu usuario para iniciar sesión.',
                    children: [
                      LabeledTextField(
                        label: 'Correo',
                        controller: _email,
                        hint: 'correo@ejemplo.com',
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        bottomPadding: 0,
                      ),
                    ],
                  ),
                  if (widget.canChangePassword) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildPasswordSection(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Guardar cambios',
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    final textTheme = Theme.of(context).textTheme;
    return FormSectionCard(
      title: 'Seguridad',
      subtitle:
          'Cambiar contraseña es opcional. Déjalo vacío para conservar la actual.',
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
    );
  }
}
