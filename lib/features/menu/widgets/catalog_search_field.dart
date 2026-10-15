import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Campo "Buscar..." en forma de pastilla celeste (Figma), compartido por el
/// catálogo del padre, el del docente y el del POS.
class CatalogSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.ink900.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.ink900,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppColors.teal50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.fullAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.fullAll,
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.fullAll,
            borderSide: BorderSide(color: AppColors.teal500, width: 1.5),
          ),
        ),
      ),
    );
  }
}
