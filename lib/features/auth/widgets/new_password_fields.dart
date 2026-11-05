import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_text_field.dart';
import 'password_requirements.dart';

/// New password + confirmation with the live requirements guide and the
/// "do not match" notice. Reusable by every screen that sets a password; the
/// screen owns (and disposes) the controllers and validates with
/// `checkNewPassword`.
class NewPasswordFields extends StatelessWidget {
  const NewPasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmController,
    this.passwordHint = 'Nueva contraseña',
    this.confirmHint = 'Confirmar nueva contraseña',
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String passwordHint;
  final String confirmHint;

  @override
  Widget build(BuildContext context) {
    // Repaints by itself while the user types in either field.
    return ListenableBuilder(
      listenable: Listenable.merge([passwordController, confirmController]),
      builder: (context, _) {
        final password = passwordController.text;
        final confirmation = confirmController.text;
        final mismatch = confirmation.isNotEmpty && confirmation != password;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: passwordController,
              hint: passwordHint,
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            PasswordRequirements(password: password),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              controller: confirmController,
              hint: confirmHint,
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            if (mismatch)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Las contraseñas no coinciden',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
