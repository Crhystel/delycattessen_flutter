import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Purple label over an outlined text field, the style of the registration
/// forms. Used by the profile edit screens of parents, teachers and children.
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const border = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: BorderSide(color: AppColors.secondary500, width: 1.4),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
            child: Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary500,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.secondary500,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
