import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Purple label over an outlined text field, the style of the registration
/// forms. Used by the profile edit screens of parents, teachers and children.
/// With [isPassword] the text is hidden and a show/hide toggle is added.
class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool isPassword;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.isPassword = false,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _obscure = true;

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
              widget.label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary500,
              ),
            ),
          ),
          TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.isPassword
                ? TextCapitalization.none
                : widget.textCapitalization,
            obscureText: widget.isPassword && _obscure,
            style: const TextStyle(color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: widget.hint,
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
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.ink900,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
