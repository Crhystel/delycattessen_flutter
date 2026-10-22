import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Single source of truth for the app theme.
/// Roles: teal = structure, brand (yellow) = action, secondary (purple) = accent only.
class AppTheme {
  /// Estilo de AppBar clara (fondo blanco, flecha y título en AppColors.ink900)
  /// según especificaciones del Figma (fuente Nunito, weight 800, tamaño 20).
  static AppBarTheme get lightAppBarTheme => AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.ink900,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: AppColors.ink900),
    titleTextStyle: GoogleFonts.nunito(
      color: AppColors.ink900,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );

  /// Helper para construir una AppBar clara estándar del tema sin colores escritos a mano.
  static AppBar lightAppBar({
    Widget? title,
    Widget? leading,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink900,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.ink900),
      titleTextStyle: GoogleFonts.nunito(
        color: AppColors.ink900,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal500,
      primary: AppColors.teal500,
      onPrimary: Colors.white,
      secondary: AppColors.brand500,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.secondary500,
      surface: Colors.white,
      onSurface: AppColors.ink900,
      error: AppColors.danger500,
    );

    // Built once; individual screens inherit it instead of calling GoogleFonts inline.
    final textTheme = GoogleFonts.nunitoTextTheme().apply(
      bodyColor: AppColors.ink900,
      displayColor: AppColors.ink900,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink50,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.teal500,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.teal50, width: 1.2),
        ),
        hintStyle: TextStyle(
          color: AppColors.ink900.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.teal500, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.brand500,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.ink900 : AppColors.teal500,
          );
        }),
      ),
    );
  }
}
