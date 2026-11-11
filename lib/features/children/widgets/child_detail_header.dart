import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/subpage_header.dart';
import '../../auth/models/auth_models.dart';
import 'child_avatar.dart';

/// Cabecera morada de la ficha del hijo: botones de volver y editar, avatar,
/// nombre y colegio sobre tres círculos translúcidos. Llega hasta el borde
/// superior de la pantalla (suma la zona de la barra de estado a su margen).
class ChildDetailHeader extends StatelessWidget {
  const ChildDetailHeader({
    super.key,
    required this.child,
    required this.onBack,
    required this.onEdit,
  });

  final Child child;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  /// Lado del avatar (88) y su borde blanco (4).
  static const double _avatarRadius = 40;
  static const double _avatarBorder = 4;

  /// Lo que la tarjeta de saldo sube sobre la cabecera.
  static const double balanceOverlap = 60;

  /// El avatar sube sobre la fila de botones, como en el diseño.
  static const double _avatarLift = 8;

  /// Franja bajo el subtítulo: la que cubre la tarjeta más un respiro.
  static const double _bottomPadding = 84;

  @override
  Widget build(BuildContext context) {
    final top = AppLayout.pageTopPadding(context, extra: 12);
    return ClipRect(
      child: ColoredBox(
        color: AppColors.secondary500,
        child: Stack(
          children: [
            const Positioned(top: -70, right: -60, child: _Circle(200, 0.10)),
            const Positioned(top: 160, right: -36, child: _Circle(110, 0.08)),
            const Positioned(bottom: -60, left: -40, child: _Circle(150, 0.08)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                top,
                AppSpacing.md,
                _bottomPadding - _avatarLift,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SubpageBackButton(onColor: true, onPressed: onBack),
                      _EditButton(
                        tooltip: 'Editar datos de ${child.firstName}',
                        onPressed: onEdit,
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_avatarLift),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(_avatarBorder),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ChildAvatar(
                            child: child,
                            radius: _avatarRadius,
                            fixedTint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          child.displayName,
                          textAlign: TextAlign.center,
                          style: AppText.pageTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          child.institutionName,
                          textAlign: TextAlign.center,
                          style: AppText.secondaryLg.copyWith(
                            fontSize: 14.5,
                            color: AppColors.secondary50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.opacity);

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          child: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
