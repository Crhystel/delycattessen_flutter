import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/settings_row.dart';
import 'change_email_screen.dart';
import 'edit_names_screen.dart';
import 'profile_password_screen.dart';

/// "Mi perfil" of a parent or teacher (the same look for both): who is signed in and a list of options,
/// each with an arrow that opens its own screen (names, email, password and,
/// for teachers, allergies). Pops with the latest [MeResponse] when something
/// changed, so the caller can refresh its greeting.
class ProfileScreen extends StatefulWidget {
  final MeResponse me;
  final AuthService? authService;

  /// Opens the allergies of the person. Only teachers have their own, so the
  /// row shows up only when the caller provides this (it lives in `users`,
  /// which `auth` must not import).
  final VoidCallback? onOpenAllergies;

  /// Sección extra bajo "Cuenta" (el padre pone aquí "Mis hijos", que vive en
  /// `children` y `auth` no puede importar).
  final Widget? extraSections;

  /// Si se da, se muestra el botón "Cerrar sesión" al final.
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key,
    required this.me,
    this.authService,
    this.onOpenAllergies,
    this.extraSections,
    this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late MeResponse _me = widget.me;
  late final AuthService _authService = widget.authService ?? AuthService();
  bool _changed = false;

  Future<void> _open(Widget screen) async {
    final result = await Navigator.of(
      context,
    ).push<Object?>(MaterialPageRoute(builder: (_) => screen));
    if (!mounted || result is! MeResponse) return;
    setState(() {
      _me = result;
      _changed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allergies = widget.onOpenAllergies;
    return PopScope(
      // Leaving after a change hands back the latest profile.
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_me);
      },
      child: FormPage(
        title: 'Mi perfil',
        children: [
          ProfileSummaryCard(
            design: true,
            leading: InitialsAvatar(
              name: _me.displayName,
              fallback: _me.email,
              radius: 32,
              solid: true,
            ),
            title: _me.displayName.isEmpty ? 'Mi perfil' : _me.displayName,
            subtitle: _me.email,
          ),
          const SizedBox(height: AppSpacing.xl),
          FormSectionCard(
            design: true,
            title: 'Cuenta',
            contentPadding: EdgeInsets.zero,
            children: withDividers([
              SettingsRow(
                design: true,
                icon: Icons.badge_outlined,
                title: 'Nombres',
                subtitle: _me.fullName,
                onTap: () =>
                    _open(EditNamesScreen(me: _me, authService: _authService)),
              ),
              SettingsRow(
                design: true,
                icon: Icons.mail_outline,
                title: 'Correo',
                subtitle: _me.email,
                onTap: () => _open(
                  ChangeEmailScreen(me: _me, authService: _authService),
                ),
              ),
              SettingsRow(
                design: true,
                icon: Icons.lock_outline,
                title: 'Contraseña',
                subtitle: 'Cambia tu contraseña',
                onTap: () =>
                    _open(ProfilePasswordScreen(authService: _authService)),
              ),
            ], design: true),
          ),
          if (allergies != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FormSectionCard(
              design: true,
              title: 'Salud',
              contentPadding: EdgeInsets.zero,
              children: [
                SettingsRow(
                  design: true,
                  icon: Icons.health_and_safety_outlined,
                  title: 'Alergias',
                  subtitle: 'Gestiona tus alergias',
                  onTap: allergies,
                ),
              ],
            ),
          ],
          if (widget.extraSections != null) ...[
            const SizedBox(height: AppSpacing.xl),
            widget.extraSections!,
          ],
          if (widget.onLogout != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _LogoutButton(onPressed: widget.onLogout!),
          ],
        ],
      ),
    );
  }
}

/// "Cerrar sesión": 54 de alto, fondo blanco, borde de
/// 1.5 en rojo y texto rojo oscuro 16/800 con icono de 20.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout, size: 20),
      label: Text(
        'Cerrar sesión',
        style: AppText.button.copyWith(color: AppColors.danger700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.danger700,
        side: const BorderSide(color: AppColors.danger500, width: 1.5),
        shape: const StadiumBorder(),
      ),
    );
  }
}
