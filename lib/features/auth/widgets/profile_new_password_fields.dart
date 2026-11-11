import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/labeled_text_field.dart';
import 'password_requirements.dart';

/// New password + live requirements guide + confirmation (with the "do not
/// match" notice), in the labeled-field style of the profile forms. The screen
/// owns and disposes the controllers and validates with `checkNewPassword`.
class ProfileNewPasswordFields extends StatelessWidget {
  const ProfileNewPasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmController,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledTextField(
          label: 'Nueva contraseña',
          controller: passwordController,
          hint: 'Crea una contraseña segura',
          isPassword: true,
          bottomPadding: 0,
        ),
        ListenableBuilder(
          listenable: passwordController,
          builder: (context, _) =>
              PasswordRequirements(password: passwordController.text),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: 'Confirmar nueva contraseña',
          controller: confirmController,
          hint: 'Repite la nueva contraseña',
          isPassword: true,
          bottomPadding: 0,
        ),
        ListenableBuilder(
          listenable: Listenable.merge([passwordController, confirmController]),
          builder: (context, _) {
            final mismatch =
                confirmController.text.isNotEmpty &&
                confirmController.text != passwordController.text;
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
