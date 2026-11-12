import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/photo_source_dialog.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../../../core/widgets/subpage_header.dart';
import '../../../core/widgets/terms_checkbox.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/settings_row.dart';
import '../../users/screens/allergy_management_screen.dart';
import '../../users/services/allergy_owner.dart';
import '../providers/child_settings_controller.dart';
import '../utils/allergy_summary.dart';
import '../utils/child_account_text.dart';
import '../utils/parental_control_summary.dart';
import '../widgets/child_photo_avatar.dart';
import 'deactivate_child_screen.dart';
import 'edit_child_names_screen.dart';
import 'edit_child_password_screen.dart';
import 'edit_child_username_screen.dart';
import 'parental_control_screen.dart';

/// "Datos del hijo": menú con su cuenta (nombres, usuario y contraseña, cada
/// uno en su propia pantalla) y su configuración (control parental y alergias),
/// más el cambio de foto, que también actualiza el reconocimiento facial. Pops
/// with the updated [Child] when the names, username or photo changed.
class EditChildScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  /// Resúmenes de alergias y control parental; se crea solo si no se da.
  final ChildSettingsController? settings;

  const EditChildScreen({
    super.key,
    required this.child,
    this.authService,
    this.settings,
  });

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final ChildSettingsController _settings;
  late final bool _ownsSettings;
  late Child _child = widget.child;
  bool _isUpdatingPhoto = false;
  // Names or photo changed: the updated child is returned on exit.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _ownsSettings = widget.settings == null;
    _settings =
        widget.settings ??
        ChildSettingsController(
          studentId: widget.child.id,
          authService: widget.authService,
        );
    _settings.load();
  }

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  /// Opens one of the child's edit screens; the names and the username come
  /// back as the updated [Child].
  Future<void> _openEditor(Widget screen) async {
    final updated = await Navigator.of(
      context,
    ).push<Child>(MaterialPageRoute(builder: (_) => screen));
    if (updated == null || !mounted) return;
    setState(() {
      _child = updated;
      _changed = true;
    });
  }

  Future<void> _openParentalControl() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentalControlScreen(
          studentId: _child.id,
          studentName: _child.displayName,
        ),
      ),
    );
    if (!mounted) return;
    _settings.loadParentalControl();
  }

  Future<void> _openAllergies() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          owner: StudentAllergyOwner(_child.id, authService: _authService),
          personName: _child.displayName,
          parentStyle: true,
        ),
      ),
    );
    if (!mounted) return;
    _settings.loadAllergies();
  }

  /// The removal screen leaves this flow itself once the child is removed.
  Future<void> _openRemoval() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            DeactivateChildScreen(child: _child, authService: _authService),
      ),
    );
  }

  Future<void> _updatePhoto() async {
    // The new photo feeds the facial recognition: the backend keeps the
    // acceptance of the terms as legal evidence.
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => const _PhotoTermsDialog(),
    );
    if (accepted != true || !mounted) return;
    final photo = await PhotoSourceDialog.show(
      context,
      title: 'Foto de ${_child.firstName}',
    );
    if (photo == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      final updated = await _authService.updateChildPhoto(
        _child.id,
        photo.path,
      );
      if (!mounted) return;
      setState(() {
        _child = updated;
        _changed = true;
        _isUpdatingPhoto = false;
      });
      showSuccessSnackBar(
        'La foto de perfil y el reconocimiento facial se han actualizado con éxito.',
        title: 'Foto actualizada',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPhoto = false);
      showErrorSnackBar(errorMessageOf(e), title: 'Error al actualizar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Si cambió algo, se devuelve el hijo actualizado al salir.
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_child);
      },
      child: Scaffold(
        backgroundColor: AppColors.ink50,
        body: Stack(
          children: [
            const RepaintBoundary(
              child: FloatingBubbles(
                corner: BubbleCorner.topRight,
                design: true,
              ),
            ),
            ResponsiveCenter(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SubpageHeader(title: 'Datos de tu hijo/a'),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        14,
                        AppSpacing.page,
                        AppSpacing.xl +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileSummaryCard(
                            design: true,
                            leading: ChildPhotoAvatar(
                              child: _child,
                              isUpdating: _isUpdatingPhoto,
                              onChangePhoto: _updatePhoto,
                            ),
                            title: _child.displayName,
                            subtitle: _child.institutionName,
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
                                subtitle: _child.fullName,
                                onTap: () => _openEditor(
                                  EditChildNamesScreen(
                                    child: _child,
                                    authService: _authService,
                                  ),
                                ),
                              ),
                              SettingsRow(
                                design: true,
                                icon: Icons.person_outline,
                                title: 'Usuario',
                                subtitle: _child.usernameSummary,
                                onTap: () => _openEditor(
                                  EditChildUsernameScreen(
                                    child: _child,
                                    authService: _authService,
                                  ),
                                ),
                              ),
                              SettingsRow(
                                design: true,
                                icon: Icons.lock_outline,
                                title: 'Contraseña',
                                subtitle:
                                    'Cambia la contraseña de '
                                    '${_child.firstName}',
                                onTap: () => _openEditor(
                                  EditChildPasswordScreen(
                                    child: _child,
                                    authService: _authService,
                                  ),
                                ),
                              ),
                            ], design: true),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ListenableBuilder(
                            listenable: _settings,
                            builder: (context, _) => FormSectionCard(
                              design: true,
                              title: 'Configuración',
                              contentPadding: EdgeInsets.zero,
                              children: withDividers([
                                SettingsRow(
                                  design: true,
                                  icon: Icons.shield_outlined,
                                  title: 'Control parental',
                                  subtitle: ParentalControlSummary.brief(
                                    _settings.parentalControl,
                                  ),
                                  onTap: _openParentalControl,
                                ),
                                SettingsRow(
                                  design: true,
                                  icon: Icons.warning_amber_outlined,
                                  title: 'Alergias',
                                  subtitle: AllergySummary.of(
                                    _settings.allergies,
                                  ),
                                  onTap: _openAllergies,
                                ),
                              ], design: true),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FormSectionCard(
                            design: true,
                            title: 'Cuenta de ${_child.firstName}',
                            contentPadding: EdgeInsets.zero,
                            children: [
                              SettingsRow(
                                design: true,
                                destructive: true,
                                icon: Icons.person_remove_outlined,
                                title: 'Dar de baja a ${_child.firstName}',
                                subtitle:
                                    'Solo sin saldo ni preórdenes pendientes',
                                onTap: _openRemoval,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the terms before a new photo of the child is taken.
class _PhotoTermsDialog extends StatefulWidget {
  const _PhotoTermsDialog();

  @override
  State<_PhotoTermsDialog> createState() => _PhotoTermsDialogState();
}

class _PhotoTermsDialogState extends State<_PhotoTermsDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar foto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La foto se usa para el reconocimiento facial en la caja.',
          ),
          const SizedBox(height: AppSpacing.md),
          TermsCheckbox(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _accepted ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
