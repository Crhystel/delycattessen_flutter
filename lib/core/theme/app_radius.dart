import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 12;

  /// Radios intermedios del rediseño del padre (campos, chips, tarjetas).
  static const double field = 14;
  static const double control = 16;
  static const double row = 18;
  static const double card = 22;
  static const double md = 20;
  static const double lg = 28;

  /// Tarjetas grandes de opción (caja) y sus iconos en tablet.
  static const double xl = 26;
  static const double xxl = 32;
  static const double iconXl = 36;
  static const double pill = 999;

  static const BorderRadius fieldAll = BorderRadius.all(Radius.circular(field));
  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius rowAll = BorderRadius.all(Radius.circular(row));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(pill));
}
