import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/primary_button.dart';
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

  /// Título + descripción a la izquierda (se ajustan al ancho disponible) y
  /// el interruptor a la derecha, para que nunca se desborde la fila.
  Widget _buildSwitchHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: AppColors.teal500),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.ink900.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.ink900,
          activeTrackColor: AppColors.brand500,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.ink50,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(title: const Text('Control de gastos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily limit section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchHeader(
                    icon: Icons.payments_outlined,
                    title: 'Límite de gasto diario',
                    subtitle: 'Máximo que puede gastar por día',
                    value: _dailyLimitEnabled,
                    onChanged: (val) =>
                        setState(() => _dailyLimitEnabled = val),
                  ),
                  if (_dailyLimitEnabled) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto máximo por día',
                        prefixText: '\$ ',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Allowed days section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchHeader(
                    icon: Icons.event_available_outlined,
                    title: 'Días permitidos',
                    subtitle: 'Días en que puede comprar',
                    value: _allowedDaysEnabled,
                    onChanged: (val) =>
                        setState(() => _allowedDaysEnabled = val),
                  ),
                  if (_allowedDaysEnabled) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Selecciona los días en los que puede comprar en el bar:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: List.generate(_weekDays.length, (index) {
                        final isSelected = _allowedDays.contains(index);
                        return ChoiceChip(
                          label: Text(_weekDays[index]),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) => _toggleDay(index),
                          selectedColor: AppColors.teal500,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.ink900.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.teal500
                                : AppColors.ink900.withValues(alpha: 0.15),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: PrimaryButton(
            label: 'Guardar cambios',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _saveData,
          ),
        ),
      ),
    );
  }
}
