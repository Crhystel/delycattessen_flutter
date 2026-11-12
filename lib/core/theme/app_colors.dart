import 'package:flutter/material.dart';

/// Brand roles:
/// - teal (azul caribe): main color, structure (headers, balance card, selection).
/// - brand (amarillo): main color, action (primary button, active tab).
/// - secondary (morado): accompanying accent only, small touches.
class AppColors {
  static const Color brand50 = Color(0xFFFEF8EC);
  static const Color brand500 = Color(0xFFE8A020);
  static const Color brand700 = Color(0xFFA87028);

  static const Color teal50 = Color(0xFFE5F3FF);
  static const Color teal500 = Color(0xFF007ACC);
  static const Color teal700 = Color(0xFF005C99);

  static const Color navActiveCircle = Color(0xFFE8B862);

  /// Borde de las tarjetas amarillas (combo, pedido pendiente). Mismo valor que
  /// [navActiveCircle]; este es el nombre que describe su uso.
  static const Color brandBorder = navActiveCircle;

  static const Color secondary50 = Color(0xFFEEE8F6);
  static const Color secondary500 = Color(0xFF5B2D9E);
  static const Color secondary700 = Color(0xFF3E1E6C);

  static const Color ink50 = Color(0xFFF2F7FB);
  static const Color ink900 = Color(0xFF0C1B2A);

  /// Texto secundario (subtítulos, etiquetas) y bordes finos de tarjetas.
  static const Color muted = Color(0xFF5E6475);
  static const Color line = Color(0xFFECEAF3);
  static const Color lineStrong = Color(0xFFE3E0EC);

  /// Divisor interno de listas dentro de una tarjeta.
  static const Color divider = Color(0xFFF0EEF5);

  /// Flechas (chevron) de las filas, placeholders y pista del interruptor
  /// apagado.
  static const Color chevron = Color(0xFF8C8FA0);
  static const Color placeholder = Color(0xFF6B7080);
  static const Color switchOff = Color(0xFFC9C6D3);

  /// Sombra suave de las burbujas y tarjetas flotantes (rgba 20,24,43 al 16%).
  static const Color shadow = Color(0x29141828);

  /// Sombra del botón morado fijo al pie (morado al 30%).
  static const Color primaryShadow = Color(0x4D5B2D9E);

  /// Botón de acción rápida de la caja ("Venta rápida") y su sombra (al 30%).
  static const Color quickAction = Color(0xFF5A32EA);
  static const Color quickActionShadow = Color(0x4D5A32EA);

  /// Sombra de la tarjeta de saldo azul (azul al 25%).
  static const Color balanceShadow = Color(0x400478C9);

  /// Hoja inferior: asa y fondo oscurecido.
  static const Color sheetHandle = Color(0xFFD5D2DE);
  static const Color sheetScrim = Color(0xFF4A4658);

  static const Color success500 = Color(0xFF1E9E6B);
  static const Color success700 = Color(0xFF167A52);
  static const Color successBg = Color(0xFFE8F6EE);

  static const Color danger500 = Color(0xFFE0473E);
  static const Color danger700 = Color(0xFFB5352D);
  static const Color dangerBg = Color(0xFFFBEAE8);

  static const Color warning500 = Color(0xFFE8A33D);
  static const Color warning700 = Color(0xFFB9802A);
  static const Color warningBg = Color(0xFFFDF3E1);
}
