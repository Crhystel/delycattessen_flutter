import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/parental_control_model.dart';
import '../services/parental_control_service.dart';

class ParentalControlScreen extends StatefulWidget {
  final int studentId;
  const ParentalControlScreen({super.key, required this.studentId});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  final _service = ParentalControlService();
  bool _isLoading = true;
  bool _isSaving = false;

  bool _dailyLimitEnabled = false;
  double _dailyLimitAmount = 0.0;
  bool _allowedDaysEnabled = false;
  List<int> _allowedDays = [];

  final List<String> _weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar controles parentales: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Control Parental', style: TextStyle(color: AppColors.ink)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Limit Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Límite de gasto diario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Switch(
                        value: _dailyLimitEnabled,
                        onChanged: (val) => setState(() => _dailyLimitEnabled = val),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_dailyLimitEnabled) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto máximo (\$) / día',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: '\$ ',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Allowed Days Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Días permitidos para compras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Switch(
                        value: _allowedDaysEnabled,
                        onChanged: (val) => setState(() => _allowedDaysEnabled = val),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_allowedDaysEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Selecciona los días en los que el estudiante puede comprar en el bar:',
                      style: TextStyle(color: AppColors.ink200, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_weekDays.length, (index) {
                        final isSelected = _allowedDays.contains(index);
                        return ChoiceChip(
                          label: Text(_weekDays[index]),
                          selected: isSelected,
                          onSelected: (_) => _toggleDay(index),
                          selectedColor: AppColors.warning100,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.warning : AppColors.ink200,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? AppColors.warning : AppColors.ink200.withOpacity(0.3),
                            ),
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
          padding: const EdgeInsets.all(24.0),
          child: CustomButton(
            text: 'Guardar Cambios',
            onPressed: _isSaving ? () {} : _saveData,
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }
}
