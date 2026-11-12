import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/danger_button.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../../auth/services/auth_service.dart';
import '../providers/children_provider.dart';

/// The parent removes a child. First it shows what has to be true (no balance,
/// no pending pre-orders, no recharge in process) and, once it is, asks for the
/// parent's own password and a final confirmation. The backend keeps the
/// history and erases the minor's photo, allergies and parental control.
///
/// Afterwards it goes back to the start of the parent area, or to the child
/// registration when no child is left.
class DeactivateChildScreen extends StatefulWidget {
  final Child child;
  final AuthService? authService;

  /// Taken from the widget tree when not given.
  final ChildrenProvider? childrenProvider;

  const DeactivateChildScreen({
    super.key,
    required this.child,
    this.authService,
    this.childrenProvider,
  });

  @override
  State<DeactivateChildScreen> createState() => _DeactivateChildScreenState();
}

class _DeactivateChildScreenState extends State<DeactivateChildScreen>
    with NotificationMixin {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _parentPassword = TextEditingController();
  ChildRemovalCheck? _check;
  String? _loadError;
  bool _isLoading = true;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _loadCheck();
  }

  @override
  void dispose() {
    _parentPassword.dispose();
    super.dispose();
  }

  Future<void> _loadCheck() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final check = await _authService.getChildRemovalCheck(widget.child.id);
      if (!mounted) return;
      setState(() {
        _check = check;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = errorMessageOf(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _remove() async {
    if (_parentPassword.text.isEmpty) {
      showWarningSnackBar(
        'Ingresa tu contraseña para confirmar.',
        title: 'Falta tu contraseña',
      );
      return;
    }
    final name = widget.child.firstName;
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Dar de baja a $name',
      message:
          'Se borrarán su foto, sus alergias y su control parental, y ya no '
          'podrá iniciar sesión. Su historial de compras se conserva. Esta '
          'acción no se puede deshacer.',
      confirmLabel: 'Dar de baja',
      icon: Icons.person_remove_outlined,
    );
    if (!confirmed || !mounted) return;

    final provider =
        widget.childrenProvider ?? context.read<ChildrenProvider>();
    setState(() => _isRemoving = true);
    try {
      await provider.removeChild(
        widget.child.id,
        parentPassword: _parentPassword.text,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo dar de baja');
      setState(() => _isRemoving = false);
      // The conditions may have changed since the screen opened.
      _loadCheck();
      return;
    }
    if (!mounted) return;
    showSuccessSnackBar(
      '$name ya no está en tu cuenta.',
      title: 'Hijo dado de baja',
    );
    final navigator = Navigator.of(context);
    if (provider.children.isEmpty) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
        (route) => false,
      );
    } else {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.child.firstName;
    return FormPage(
      title: 'Dar de baja',
      children: [
        FormSectionCard(
          design: true,
          title: 'Antes de continuar',
          subtitle:
              'Para dar de baja a $name no debe tener saldo, preórdenes '
              'pendientes ni una recarga en proceso.',
          children: [_buildConditions()],
        ),
        if (_check?.canRemove ?? false) ...[
          const SizedBox(height: AppSpacing.xl),
          FormSectionCard(
            design: true,
            title: 'Confirma que eres tú',
            subtitle:
                'Es irreversible: se borran su foto, alergias y control '
                'parental.',
            children: [
              LabeledTextField(
                label: 'Tu contraseña',
                controller: _parentPassword,
                hint: 'Escribe tu contraseña para confirmar',
                isPassword: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          DangerButton(
            label: 'Dar de baja a $name',
            icon: Icons.person_remove_outlined,
            isLoading: _isRemoving,
            onPressed: _remove,
          ),
        ],
      ],
    );
  }

  Widget _buildConditions() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary500),
        ),
      );
    }
    final check = _check;
    if (check == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_loadError ?? 'No se pudo revisar.', style: AppText.secondary),
          TextButton(onPressed: _loadCheck, child: const Text('Reintentar')),
        ],
      );
    }
    return Column(
      children: [
        _ConditionRow(
          met: check.balance == null,
          title: 'Sin saldo en la billetera',
          detail: check.balance == null
              ? null
              : 'Todavía tiene \$${check.balance!.toStringAsFixed(2)}',
        ),
        _ConditionRow(
          met: check.pendingPreOrders == 0,
          title: 'Sin preórdenes pendientes',
          detail: check.pendingPreOrders == 0
              ? null
              : _count(check.pendingPreOrders, 'preorden', 'preórdenes'),
        ),
        _ConditionRow(
          met: check.pendingRecharges == 0,
          title: 'Sin recargas en proceso',
          detail: check.pendingRecharges == 0
              ? null
              : _count(check.pendingRecharges, 'recarga', 'recargas'),
        ),
      ],
    );
  }

  static String _count(int n, String one, String many) =>
      '$n ${n == 1 ? one : many} por resolver';
}

/// One condition of the list: a check when it is met, a cross with the reason
/// when it is not.
class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.met, required this.title, this.detail});

  final bool met;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: met ? AppColors.success500 : AppColors.danger500,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.rowTitle),
                if (detail != null) Text(detail, style: AppText.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
