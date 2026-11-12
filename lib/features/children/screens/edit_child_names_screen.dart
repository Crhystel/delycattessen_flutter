import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';

/// The parent edits the four name parts of a child. Pops with the updated
/// [Child] after saving.
class EditChildNamesScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  const EditChildNamesScreen({
    super.key,
    required this.child,
    this.authService,
  });

  @override
  State<EditChildNamesScreen> createState() => _EditChildNamesScreenState();
}

class _EditChildNamesScreenState extends State<EditChildNamesScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final _firstName = TextEditingController(text: widget.child.firstName);
  late final _secondName = TextEditingController(text: widget.child.secondName);
  late final _lastName = TextEditingController(text: widget.child.lastName);
  late final _secondLastName = TextEditingController(
    text: widget.child.secondLastName,
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
    final update = ChildProfileUpdate.names(
      PersonNames(
        firstName: _firstName.text,
        secondName: _secondName.text,
        lastName: _lastName.text,
        secondLastName: _secondLastName.text,
      ),
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
        'Los nombres de ${updated.firstName} se guardaron correctamente.',
        title: 'Datos actualizados',
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
          title: 'Nombres de ${widget.child.firstName}',
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
