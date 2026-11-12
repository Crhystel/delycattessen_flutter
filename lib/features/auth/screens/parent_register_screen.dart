import 'package:flutter/material.dart';

import '../utils/password_check.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/terms_checkbox.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../widgets/new_password_fields.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'student_registration_screen.dart';
import '../../../core/utils/error_message.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final issue = checkNewPassword(
      _passwordController.text,
      confirmation: _confirmController.text,
    );
    if (issue != null) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: issue.title,
        message: issue.message,
      );
      return;
    }
    if (!_acceptedTerms) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Términos y condiciones',
        message: 'Debes aceptar los términos y condiciones.',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.registerParent(
        ParentRegistration(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirm: _confirmController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'No se pudo completar el registro',
        message: errorMessageOf(e),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      showBackButton: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      icon: Icons.person_add_alt_1,
      title: 'Registrarse',
      subtitle: null,
      children: [
        AuthTextField(
          controller: _emailController,
          hint: 'E-mail',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        NewPasswordFields(
          passwordController: _passwordController,
          confirmController: _confirmController,
          passwordHint: 'Contraseña',
          confirmHint: 'Confirmar Contraseña',
        ),
        const SizedBox(height: AppSpacing.md),
        TermsCheckbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Siguiente',
          isLoading: _isLoading,
          onPressed: _next,
        ),
      ],
    );
  }
}
