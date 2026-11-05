import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';

/// The parent edits a child's four name parts and username. The photo is
/// changed from the child's detail screen because it also updates the face
/// recognition. Pops with the updated [Child] after saving.
class EditChildScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  const EditChildScreen({super.key, required this.child, this.authService});

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final _firstName = TextEditingController(text: widget.child.firstName);
  late final _secondName = TextEditingController(text: widget.child.secondName);
  late final _lastName = TextEditingController(text: widget.child.lastName);
  late final _secondLastName = TextEditingController(
    text: widget.child.secondLastName,
  );
  late final _username = TextEditingController(text: widget.child.username);
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _secondName,
      _lastName,
      _secondLastName,
      _username,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final update = ChildProfileUpdate(
      names: PersonNames(
        firstName: _firstName.text,
        secondName: _secondName.text,
        lastName: _lastName.text,
        secondLastName: _secondLastName.text,
      ),
      username: _username.text,
    );
    final error = update.validate();
    if (error != null) {
      showWarningSnackBar(error, title: 'Revisa los datos');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateChildProfile(
        widget.child.id,
        update,
      );
      if (!mounted) return;
      showSuccessSnackBar(
        'Los datos de ${updated.firstName} se guardaron correctamente.',
        title: 'Datos actualizados',
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _displayName => [
    widget.child.firstName,
    widget.child.lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppTheme.lightAppBar(
        title: const Text('Datos de tu hijo/a'),
        backgroundColor: AppColors.ink50,
      ),
      body: ResponsiveCenter(
        maxWidth: AppLayout.formMaxWidth,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileSummaryCard(
                  leading: ChildAvatarChip(
                    imageUrl: widget.child.profilePictureUrl,
                  ),
                  title: _displayName,
                  subtitle: widget.child.institutionName,
                ),
                const SizedBox(height: AppSpacing.xl),
                FormSectionCard(
                  title: 'Nombres',
                  children: [
                    LabeledTextField(
                      label: 'Primer nombre',
                      controller: _firstName,
                      hint: 'Primer nombre de tu hijo/a',
                    ),
                    LabeledTextField(
                      label: 'Segundo nombre',
                      controller: _secondName,
                      hint: 'Segundo nombre (opcional)',
                    ),
                    LabeledTextField(
                      label: 'Primer apellido',
                      controller: _lastName,
                      hint: 'Primer apellido de tu hijo/a',
                    ),
                    LabeledTextField(
                      label: 'Segundo apellido',
                      controller: _secondLastName,
                      hint: 'Segundo apellido (opcional)',
                      bottomPadding: 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FormSectionCard(
                  title: 'Acceso',
                  subtitle: 'Con este usuario inicia sesión tu hijo/a.',
                  children: [
                    LabeledTextField(
                      label: 'Usuario',
                      controller: _username,
                      hint: 'Usuario con el que inicia sesión',
                      textCapitalization: TextCapitalization.none,
                      bottomPadding: 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Guardar cambios',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
