import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/subpage_header.dart';
import '../models/parental_control_model.dart';
import '../services/parental_control_service.dart';
import '../widgets/amount_field.dart';
import '../widgets/parental_control_card.dart';
import '../widgets/weekday_selector.dart';

/// Control parental de un hijo: límite de gasto diario, días permitidos y aviso
/// de saldo bajo. [studentName] es el subtítulo de la cabecera.
class ParentalControlScreen extends StatefulWidget {
  final int studentId;
  final String? studentName;
  final ParentalControlService? service;

  const ParentalControlScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.service,
  });

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen>
    with NotificationMixin {
  late final ParentalControlService _service =
      widget.service ?? ParentalControlService();
  bool _isLoading = true;
  bool _isSaving = false;

  bool _dailyLimitEnabled = false;
  bool _allowedDaysEnabled = false;
  List<int> _allowedDays = [];
  bool _lowBalanceEnabled = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _lowBalanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _lowBalanceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final control = await _service.getParentalControl(widget.studentId);
      if (!mounted) return;
      setState(() {
        _dailyLimitEnabled = control.dailyLimitEnabled;
        _allowedDaysEnabled = control.allowedDaysEnabled;
        _allowedDays = List.of(control.allowedDays);
        _amountController.text = control.dailyLimitAmount.toStringAsFixed(2);
        _lowBalanceEnabled = control.lowBalanceAlertEnabled;
        _lowBalanceController.text = control.lowBalanceAlertAmount
            .toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        errorMessageOf(e),
        title: 'No se pudo cargar el control parental',
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveData() async {
    FocusScope.of(context).unfocus(); // hide keyboard before saving
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    // An enabled limit of $0 would block every purchase: require a real amount.
    if (_dailyLimitEnabled && amount <= 0) {
      showWarningSnackBar(
        'Ingresa un monto mayor a \$0 o desactiva el límite de gasto.',
        title: 'Monto inválido',
      );
      return;
    }
    final lowBalance = double.tryParse(_lowBalanceController.text) ?? 0.0;
    if (_lowBalanceEnabled && lowBalance <= 0) {
      showWarningSnackBar(
        'Ingresa un monto mayor a \$0 o desactiva el aviso de saldo bajo.',
        title: 'Monto inválido',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final control = ParentalControl(
        dailyLimitEnabled: _dailyLimitEnabled,
        dailyLimitAmount: amount,
        allowedDaysEnabled: _allowedDaysEnabled,
        allowedDays: _allowedDays,
        lowBalanceAlertEnabled: _lowBalanceEnabled,
        lowBalanceAlertAmount: lowBalance,
      );
      await _service.updateParentalControl(widget.studentId, control);
      if (!mounted) return;
      showSuccessSnackBar('Configuración guardada exitosamente');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo guardar');
      setState(() => _isSaving = false);
    }
  }

  void _toggleDay(int index) {
    setState(() {
      if (_allowedDays.contains(index)) {
        _allowedDays.remove(index);
      } else {
        _allowedDays.add(index);
      }
    });
  }

  /// Page frame: `ink50` background with brand bubbles in the top and bottom
  /// corners. The keyboard only pads the content, so the bubbles stay anchored
  /// to the screen corners.
  Widget _frame({required Widget child}) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topRight, design: true),
          ),
          const RepaintBoundary(
            child: FloatingBubbles(
              corner: BubbleCorner.bottomRight,
              design: true,
            ),
          ),
          ResponsiveCenter(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  SubpageHeader(
                    title: 'Control parental',
                    subtitle: widget.studentName,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return Column(
      children: [
        ParentalControlCard(
          glyph: '\$',
          title: 'Límite de gasto',
          subtitle: 'Monto máximo diario',
          enabled: _dailyLimitEnabled,
          onChanged: (val) => setState(() => _dailyLimitEnabled = val),
          child: AmountField(
            controller: _amountController,
            semanticLabel: 'Monto máximo diario',
          ),
        ),
        const SizedBox(height: 14),
        ParentalControlCard(
          icon: Icons.event_available_outlined,
          title: 'Días permitidos',
          subtitle: 'Días en que puede comprar',
          enabled: _allowedDaysEnabled,
          onChanged: (val) => setState(() => _allowedDaysEnabled = val),
          offChild: Text(
            'Puede comprar todos los días. Actívalo para elegir días.',
            style: AppText.secondary,
          ),
          child: WeekdaySelector(
            selectedDays: _allowedDays,
            onToggle: _toggleDay,
          ),
        ),
        const SizedBox(height: 14),
        ParentalControlCard(
          icon: Icons.notifications_active_outlined,
          title: 'Aviso de saldo bajo',
          subtitle: 'Te avisamos antes de que se quede sin saldo',
          enabled: _lowBalanceEnabled,
          onChanged: (val) => setState(() => _lowBalanceEnabled = val),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Avisarme cuando el saldo baje de',
                style: AppText.secondaryLg.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountField(
                controller: _lowBalanceController,
                semanticLabel: 'Monto mínimo para el aviso',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'El aviso aparece en Inicio con botones de recarga rápida.',
                style: AppText.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _frame(
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary500),
        ),
      );
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return _frame(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                14,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: _buildCards(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              14,
              AppSpacing.page,
              math.max(AppSpacing.page, bottomInset + AppSpacing.sm),
            ),
            child: PrimaryButton(
              design: true,
              shadow: true,
              label: 'Guardar cambios',
              icon: Icons.save_outlined,
              isLoading: _isSaving,
              onPressed: _saveData,
            ),
          ),
        ],
      ),
    );
  }
}
