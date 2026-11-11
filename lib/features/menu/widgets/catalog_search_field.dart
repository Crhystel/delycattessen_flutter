import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Campo de búsqueda en forma de pastilla, compartido por el catálogo del
/// padre, el del docente y el del POS. Por defecto es la pastilla celeste de
/// 42 px del Figma; con [outlined] (vista del padre) es la del rediseño:
/// blanca, de 48 px y con borde fino.
class CatalogSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool outlined;

  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar...',
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = outlined ? AppColors.muted : AppColors.ink900;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.fullAll,
      borderSide: outlined
          ? const BorderSide(color: AppColors.lineStrong)
          : BorderSide.none,
    );
    // Solo el campo se reconstruye al escribir (para el botón de limpiar): la
    // pantalla que lo aloja no necesita un setState por tecla.
    return SizedBox(
      height: outlined ? 48 : 42,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: outlined ? 15 : 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: outlined ? 15 : 14,
              fontWeight: outlined ? FontWeight.w600 : null,
              color: outlined
                  ? AppColors.placeholder
                  : AppColors.ink900.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(Icons.search, size: 20, color: iconColor),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: outlined ? Colors.white : AppColors.teal50,
            contentPadding: EdgeInsets.symmetric(horizontal: outlined ? 8 : 16),
            border: border,
            enabledBorder: border,
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.fullAll,
              borderSide: BorderSide(color: AppColors.teal500, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
