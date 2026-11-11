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

/// The parent edits the username a child signs in with. Pops with the updated
/// [Child] after saving.
class EditChildUsernameScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  const EditChildUsernameScreen({
    super.key,
    required this.child,
    this.authService,
  });

  @override
  State<EditChildUsernameScreen> createState() =>
      _EditChildUsernameScreenState();
}

class _EditChildUsernameScreenState extends State<EditChildUsernameScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final _username = TextEditingController(text: widget.child.username);
  bool _isSaving = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final update = ChildProfileUpdate.username(_username.text);
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
        'El usuario de ${updated.firstName} se actualizó. Debe usarlo la '
        'próxima vez que inicie sesión.',
        title: 'Usuario actualizado',
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
      title: 'Usuario',
      children: [
        FormSectionCard(
          design: true,
          title: 'Usuario de ${widget.child.firstName}',
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
          design: true,
          shadow: true,
          label: 'Guardar usuario',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
