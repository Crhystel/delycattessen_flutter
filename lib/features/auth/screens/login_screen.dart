import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'parent_register_screen.dart';
import 'change_password_screen.dart';
import '../utils/auth_routing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with NotificationMixin {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.login(
        LoginRequest(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
      if (!mounted) return;

      final me = await _authService.getMe();
      if (!mounted) return;

      final usernameFallback = _usernameController.text.trim();

      if (me.mustChangePassword) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
              me: me,
              usernameFallback: usernameFallback,
            ),
          ),
          (route) => false,
        );
        return;
      }

      routeAfterAuth(context, me, usernameFallback: usernameFallback);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo iniciar sesión',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      icon: Icons.restaurant,
      title: '¡Bienvenido!',
      subtitle: 'Ingresa para pedir el almuerzo de tus hijos',
      footer: [
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ParentRegisterScreen()),
          ),
          child: const Text(
            '¿No tienes cuenta? Regístrate',
            style: TextStyle(
              color: AppColors.teal700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // TODO: agregar "Olvidé mi contraseña" cuando exista el flujo.
      ],
      children: [
        AuthTextField(
          controller: _usernameController,
          hint: 'Usuario',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _passwordController,
          hint: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Acceder',
          isLoading: _isLoading,
          onPressed: _login,
        ),
      ],
    );
  }
}
