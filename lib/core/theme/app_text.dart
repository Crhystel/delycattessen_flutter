import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Escala tipográfica del rediseño del padre (Nunito). Es opt-in: las pantallas
/// que siguen el diseño la usan directamente; el `textTheme` global (que usan
/// estudiante, docente y caja) no cambia.
///
/// Todos los estilos salen de [_base], así cambiar la fuente (por ejemplo a una
/// empaquetada en `assets/fonts`) se hace en un solo lugar.
class AppText {
  AppText._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.ink900,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Título de pestaña (Menú, Pedidos, Billetera…).
  static final TextStyle tabTitle = _base(
    size: 30,
    weight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  /// Saludo de Inicio.
  static final TextStyle greeting = _base(
    size: 27,
    weight: FontWeight.w800,
    letterSpacing: -0.27,
  );

  /// Título de subpantalla (ficha, control parental, perfil…).
  static final TextStyle pageTitle = _base(size: 25, weight: FontWeight.w800);

  /// Título de sección grande (Inicio, Productos).
  static final TextStyle sectionTitle = _base(
    size: 20,
    weight: FontWeight.w800,
  );

  /// Título de sección mediano (día del menú, Combos de hoy).
  static final TextStyle sectionTitleSm = _base(
    size: 19,
    weight: FontWeight.w800,
  );

  /// Título de sección compacto (Pedidos, "Su día").
  static final TextStyle sectionTitleXs = _base(
    size: 18,
    weight: FontWeight.w800,
  );

  /// Nombre principal de una fila o tarjeta.
  static final TextStyle rowTitle = _base(size: 15.5, weight: FontWeight.w700);

  /// Nombre de platillo/producto/hijo en tarjetas grandes.
  static final TextStyle cardTitle = _base(size: 17, weight: FontWeight.w700);

  /// Nombre en tarjetas medianas (hijo, alerta).
  static final TextStyle itemTitle = _base(size: 16, weight: FontWeight.w700);

  /// Texto de apoyo (subtítulos, fechas).
  static final TextStyle secondary = _base(
    size: 13,
    weight: FontWeight.w600,
    color: AppColors.muted,
  );

  static final TextStyle secondaryLg = _base(
    size: 13.5,
    weight: FontWeight.w600,
    color: AppColors.muted,
  );

  static final TextStyle caption = _base(
    size: 12.5,
    weight: FontWeight.w600,
    color: AppColors.muted,
  );

  /// Texto de enlace ("Ver menú", "Cambiar").
  static final TextStyle link = _base(
    size: 14.5,
    weight: FontWeight.w700,
    color: AppColors.secondary500,
  );

  /// Precio o monto destacado.
  static final TextStyle price = _base(size: 17, weight: FontWeight.w800);

  static final TextStyle amount = _base(size: 20, weight: FontWeight.w800);

  /// Texto de botón principal.
  static final TextStyle button = _base(
    size: 16,
    weight: FontWeight.w800,
    color: Colors.white,
  );

  /// Etiqueta de chip/insignia.
  static final TextStyle badge = _base(size: 12, weight: FontWeight.w700);

  /// Name of the item on a detail page.
  static final TextStyle detailTitle = _base(
    size: 26,
    weight: FontWeight.w800,
    letterSpacing: -0.26,
  );

  /// Price on a detail page.
  static final TextStyle detailPrice = _base(
    size: 26,
    weight: FontWeight.w800,
    color: AppColors.brand700,
  );

  /// Description under the name on a detail page.
  static final TextStyle detailSubtitle = _base(
    size: 15,
    weight: FontWeight.w600,
    color: AppColors.muted,
  );

  /// Value of an info tile ("Martes 10 nov", "En caja").
  static final TextStyle infoValue = _base(size: 15, weight: FontWeight.w700);

  /// Heading line of a notice box (allergen warning).
  static final TextStyle noteTitle = _base(size: 15, weight: FontWeight.w800);

  /// Body text of a notice box.
  static final TextStyle noteBody = _base(size: 14, weight: FontWeight.w600);

  /// Big amount on the sale receipt of the cashier.
  static final TextStyle heroAmount = _base(
    size: 42,
    weight: FontWeight.w800,
    color: AppColors.success700,
    height: 1,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Item line of a receipt.
  static final TextStyle receiptLine = _base(size: 15, weight: FontWeight.w600);

  /// Amount at the end of a receipt line.
  static final TextStyle receiptLineAmount = _base(
    size: 15,
    weight: FontWeight.w700,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Explanatory line of a receipt ("Saldo restante de …").
  static final TextStyle receiptNote = _base(
    size: 14.5,
    weight: FontWeight.w600,
    color: AppColors.muted,
  );

  /// Label floating over a photo (category, "COMBO").
  static final TextStyle tag = _base(
    size: 13,
    weight: FontWeight.w700,
    color: AppColors.secondary500,
  );
}
