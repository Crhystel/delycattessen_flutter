import 'package:flutter/material.dart';

import '../../../core/config/password_policy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/password_requirements.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'student_registration_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!PasswordPolicy.isValid(_passwordController.text)) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Contraseña insegura',
        message:
            'A tu contraseña le falta:\n${PasswordPolicy.missingSummary(_passwordController.text)}',
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Las contraseñas no coinciden',
        message: 'Verifica que ambas contraseñas sean iguales.',
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
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMismatch =
        _confirmController.text.isNotEmpty &&
        _confirmController.text != _passwordController.text;

    return AuthFormLayout(
      icon: Icons.person_add_alt_1,
      title: 'Crea tu cuenta',
      subtitle: 'Regístrate para administrar el comedor de tus hijos',
      children: [
        AuthTextField(
          controller: _emailController,
          hint: 'Correo electrónico',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _passwordController,
          hint: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirements(password: _passwordController.text),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _confirmController,
          hint: 'Confirmar contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          onChanged: (_) => setState(() {}),
        ),
        if (passwordsMismatch)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Las contraseñas no coinciden',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Siguiente',
          isLoading: _isLoading,
          onPressed: _next,
        ),
      ],
    );
  }
}
