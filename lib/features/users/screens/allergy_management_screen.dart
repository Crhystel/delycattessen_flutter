import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/allergy_models.dart';
import '../../auth/services/auth_service.dart';

class AllergyManagementScreen extends StatefulWidget {
  final int studentId;
  final String personName;

  const AllergyManagementScreen({
    super.key,
    required this.studentId,
    required this.personName,
  });

  @override
  State<AllergyManagementScreen> createState() =>
      _AllergyManagementScreenState();
}

class _AllergyManagementScreenState extends State<AllergyManagementScreen>
    with NotificationMixin {
  final _authService = AuthService();
  final _newAllergenController = TextEditingController();

  List<Allergen> _allAllergens = [];
  List<Allergen> _selectedAllergens = [];
  Allergen? _dropdownValue;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCreatingAllergen = false;
  bool _showNewAllergenField = false;

  List<Allergen> get _availableToAdd => _allAllergens
      .where((a) => !_selectedAllergens.any((s) => s.id == a.id))
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newAllergenController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final allergens = await _authService.getAllergens();
      final selected = await _authService.getStudentAllergies(widget.studentId);
      if (!mounted) return;
      setState(() {
        _allAllergens = allergens;
        _selectedAllergens = selected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _addSelected() {
    if (_dropdownValue == null) return;
    setState(() {
      _selectedAllergens.add(_dropdownValue!);
      _dropdownValue = null;
    });
  }

  void _removeAllergen(Allergen allergen) {
    setState(() => _selectedAllergens.removeWhere((a) => a.id == allergen.id));
  }

  Future<void> _createNewAllergen() async {
    final name = _newAllergenController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreatingAllergen = true);
    try {
      final created = await _authService.createAllergen(name);
      if (!mounted) return;
      setState(() {
        _allAllergens.add(created);
        _selectedAllergens.add(created);
        _newAllergenController.clear();
        _showNewAllergenField = false;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo agregar',
      );
    } finally {
      if (mounted) setState(() => _isCreatingAllergen = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final unprotected = await _authService.saveStudentAllergies(
        widget.studentId,
        _selectedAllergens.map((a) => a.id).toList(),
      );
      if (!mounted) return;
      if (unprotected.isNotEmpty) {
        showCriticalWarningSnackBar(
          'Aún no hay productos marcados con: ${unprotected.join(', ')}. '
          'Infórmaselo al personal del comedor mientras se etiquetan los productos.',
          title: 'Guardado, pero sin protección automática todavía',
        );
      } else {
        showSuccessSnackBar(
          'El registro de alergias de ${widget.personName} se guardó correctamente.',
          title: 'Alergias actualizadas',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo guardar',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(hintText: hint);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(title: Text('Alergias de ${widget.personName}')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.teal500),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registradas',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _selectedAllergens.isEmpty
                              ? Text(
                                  'Sin alergias registradas.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink900.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: _selectedAllergens.map((allergen) {
                                    return InputChip(
                                      label: Text(
                                        allergen.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brand700,
                                        ),
                                      ),
                                      backgroundColor: AppColors.brand50,
                                      side: BorderSide.none,
                                      deleteIconColor: AppColors.brand700,
                                      onDeleted: () =>
                                          _removeAllergen(allergen),
                                    );
                                  }).toList(),
                                ),
                          const SizedBox(height: AppSpacing.xl),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Añadir una alergia',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                DropdownButtonFormField<Allergen>(
                                  initialValue: _dropdownValue,
                                  items: _availableToAdd
                                      .map(
                                        (a) => DropdownMenuItem(
                                          value: a,
                                          child: Text(a.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _dropdownValue = value),
                                  decoration: _fieldDecoration('Selecciona'),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _dropdownValue == null
                                        ? null
                                        : _addSelected,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.teal700,
                                      minimumSize: const Size.fromHeight(46),
                                      side: const BorderSide(
                                        color: AppColors.teal500,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: AppRadius.mdAll,
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text(
                                      'Añadir a la lista',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (!_showNewAllergenField)
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _showNewAllergenField = true,
                                    ),
                                    child: const Text(
                                      '¿No encuentras la alergia? Agrégala',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.teal500,
                                      ),
                                    ),
                                  )
                                else
                                  _buildNewAllergenForm(),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppColors.teal500,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Los productos con estas alergias se marcarán '
                                  'automáticamente en el menú de ${widget.personName}.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.ink900.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                      AppSpacing.lg,
                    ),
                    child: PrimaryButton(
                      label: 'Guardar cambios',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNewAllergenForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _newAllergenController,
          decoration: _fieldDecoration('Ej. Arroz, Kiwi, Sésamo...'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _showNewAllergenField = false;
                  _newAllergenController.clear();
                }),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: _isCreatingAllergen ? null : _createNewAllergen,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                child: _isCreatingAllergen
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink900,
                        ),
                      )
                    : const Text('Agregar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
