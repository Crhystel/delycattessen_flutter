import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../utils/date_formatter.dart';

/// Saludo de las cabeceras de inicio: la fecha de hoy arriba
/// ("Martes, 10 de noviembre") y debajo "¡Hola, {nombre}!". Es el mismo en
/// todas las vistas con saludo (padre, estudiante, docente y caja), así que
/// cualquier cambio de formato se hace aquí.
///
/// [scale] agranda ambos textos (la caja lo usa en tablet) y [now] permite fijar
/// la fecha en las pruebas.
class GreetingText extends StatelessWidget {
  const GreetingText({super.key, required this.name, this.scale = 1, this.now});

  /// Nombre a saludar. Si está vacío se usa "Usuario".
  final String name;
  final double scale;
  final DateTime? now;

  static const double _dateSize = 14;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final date = DateFormatter.formatGreetingDate(now ?? DateTime.now());
    final shown = name.trim().isEmpty ? 'Usuario' : name.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: AppText.secondary.copyWith(fontSize: _dateSize * scale),
        ),
        SizedBox(height: _gap * scale),
        Text(
          '¡Hola, $shown!',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.greeting.copyWith(
            fontSize: (AppText.greeting.fontSize ?? 27) * scale,
          ),
        ),
      ],
    );
  }
}
