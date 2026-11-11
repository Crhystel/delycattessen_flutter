import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

/// Edits the four name parts of the signed-in parent or teacher. The email
/// goes along unchanged, so no password is needed. Pops with the updated
/// [MeResponse] after saving.
class EditNamesScreen extends StatefulWidget {
  final MeResponse me;
  final AuthService? authService;

  const EditNamesScreen({super.key, required this.me, this.authService});

  @override
  State<EditNamesScreen> createState() => _EditNamesScreenState();
}

class _EditNamesScreenState extends State<EditNamesScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final _firstName = TextEditingController(text: widget.me.firstName);
  late final _secondName = TextEditingController(text: widget.me.secondName);
  late final _lastName = TextEditingController(text: widget.me.lastName);
  late final _secondLastName = TextEditingController(
    text: widget.me.secondLastName,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _secondName,
      _lastName,
      _secondLastName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final update = ProfileUpdate(
      names: PersonNames(
        firstName: _firstName.text,
        secondName: _secondName.text,
        lastName: _lastName.text,
        secondLastName: _secondLastName.text,
      ),
      email: widget.me.email ?? '',
    );
    final error = update.validate();
    if (error != null) {
      showWarningSnackBar(error, title: 'Revisa tus datos');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateProfile(update);
      if (!mounted) return;
      showSuccessSnackBar(
        'Tus nombres se guardaron correctamente.',
        title: 'Perfil actualizado',
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo guardar');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Nombres',
      children: [
        FormSectionCard(
          design: true,
          title: 'Tus nombres',
          children: [
            LabeledTextField(
              label: 'Primer nombre',
              controller: _firstName,
              hint: 'Ingresa tu primer nombre',
            ),
            LabeledTextField(
              label: 'Segundo nombre',
              controller: _secondName,
              hint: 'Ingresa tu segundo nombre (opcional)',
            ),
            LabeledTextField(
              label: 'Primer apellido',
              controller: _lastName,
              hint: 'Ingresa tu primer apellido',
            ),
            LabeledTextField(
              label: 'Segundo apellido',
              controller: _secondLastName,
              hint: 'Ingresa tu segundo apellido (opcional)',
              bottomPadding: 0,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          design: true,
          shadow: true,
          label: 'Guardar cambios',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
