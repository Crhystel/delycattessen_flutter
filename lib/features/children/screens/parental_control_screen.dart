import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/parental_control_card.dart';
import '../models/parental_control_model.dart';
import '../services/parental_control_service.dart';

class ParentalControlScreen extends StatefulWidget {
  final int studentId;
  const ParentalControlScreen({super.key, required this.studentId});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen>
    with NotificationMixin {
  final _service = ParentalControlService();
  bool _isLoading = true;
  bool _isSaving = false;

  bool _dailyLimitEnabled = false;
  double _dailyLimitAmount = 0.0;
  bool _allowedDaysEnabled = false;
  List<int> _allowedDays = [];

  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final control = await _service.getParentalControl(widget.studentId);
      if (!mounted) return;
      setState(() {
        _dailyLimitEnabled = control.dailyLimitEnabled;
        _dailyLimitAmount = control.dailyLimitAmount;
        _allowedDaysEnabled = control.allowedDaysEnabled;
        _allowedDays = control.allowedDays;
        _amountController.text = _dailyLimitAmount.toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('Error al cargar controles parentales: $e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveData() async {
    FocusScope.of(context).unfocus(); // hide keyboard before saving
    setState(() => _isSaving = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final control = ParentalControl(
        dailyLimitEnabled: _dailyLimitEnabled,
        dailyLimitAmount: amount,
        allowedDaysEnabled: _allowedDaysEnabled,
        allowedDays: _allowedDays,
      );
      await _service.updateParentalControl(widget.studentId, control);
      if (mounted) {
        showSuccessSnackBar('Configuración guardada exitosamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('Error al guardar: $e');
        setState(() => _isSaving = false);
      }
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

  /// Page frame: white background with the brand bubbles. The keyboard only
  /// pads the content, so the bubbles stay anchored to the screen corners.
  Widget _frame({required Widget child}) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topRight),
          ),
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.bottomRight),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Control parental',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink900.withValues(alpha: 0.06),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          const Text(
            '\$',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Digits with an optional dot and up to 2 decimals (a comma would parse as 0).
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,5}\.?\d{0,2}$'),
                ),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '0.00',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.edit, size: 18, color: AppColors.secondary500),
        ],
      ),
    );
  }

  Widget _buildDayChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(_weekDays.length, (index) {
        final isSelected = _allowedDays.contains(index);
        return ChoiceChip(
          label: Text(_weekDays[index]),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => _toggleDay(index),
          selectedColor: AppColors.brand50,
          backgroundColor: AppColors.ink900.withValues(alpha: 0.06),
          side: BorderSide.none,
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.brand700
                : AppColors.ink900.withValues(alpha: 0.75),
          ),
        );
      }),
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

    return _frame(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  ParentalControlCard(
                    icon: Icons.attach_money,
                    title: 'Límite de gasto',
                    subtitle: 'Monto máximo diario',
                    enabled: _dailyLimitEnabled,
                    onChanged: (val) =>
                        setState(() => _dailyLimitEnabled = val),
                    child: _buildAmountField(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ParentalControlCard(
                    icon: Icons.event_available_outlined,
                    title: 'Días permitidos',
                    subtitle: 'Días en que puede comprar',
                    enabled: _allowedDaysEnabled,
                    onChanged: (val) =>
                        setState(() => _allowedDaysEnabled = val),
                    child: _buildDayChips(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: PrimaryButton(
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
