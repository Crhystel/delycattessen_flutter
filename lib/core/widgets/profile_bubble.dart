import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Burbuja de perfil de las pestañas del padre: círculo morado con la inicial
/// y un engranaje azul que avisa que ahí se editan los datos de la cuenta.
/// Siempre abre "Mi perfil" ([onTap]).
class ProfileBubble extends StatelessWidget {
  const ProfileBubble({super.key, required this.initial, required this.onTap});

  /// Letra que se muestra (primera del nombre o del correo).
  final String initial;
  final VoidCallback onTap;

  static const double _size = 52;
  static const double _badgeSize = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mi perfil: editar datos, hijos y cerrar sesión',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _size + 4,
          height: _size + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  initial.isEmpty ? '?' : initial.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    size: 14,
                    color: AppColors.teal500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
