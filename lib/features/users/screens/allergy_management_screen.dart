import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/floating_bubbles.dart';
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

class _AllergyManagementScreenState extends State<AllergyManagementScreen> {
  final _authService = AuthService();
  List<Allergen> _allAllergens = [];
  List<Allergen> _selectedAllergens = [];
  Allergen? _dropdownValue;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Allergen> get _availableToAdd => _allAllergens
      .where((a) => !_selectedAllergens.any((s) => s.id == a.id))
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allergens = await _authService.getAllergens();
      final selected = await _authService.getStudentAllergies(widget.studentId);
      setState(() {
        _allAllergens = allergens;
        _selectedAllergens = selected;
        _isLoading = false;
      });
    } catch (_) {
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _authService.saveStudentAllergies(
        widget.studentId,
        _selectedAllergens.map((a) => a.id).toList(),
      );
      if (!mounted) return;
      await AppNotificationDialog.show(
        context,
        type: NotificationType.success,
        title: 'Alergias actualizadas',
        message:
            'El registro de alergias de ${widget.personName} se guardó correctamente.',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'No se pudo guardar',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const FloatingBubbles(corner: BubbleCorner.topRight),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary500,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.ink900,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Text(
                              'Alergias',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Alergias registradas',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _selectedAllergens.isEmpty
                            ? Text(
                                'Sin alergias registradas.',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: AppColors.ink900.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _selectedAllergens.map((allergen) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brand50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          allergen.name,
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brand700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () =>
                                              _removeAllergen(allergen),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppColors.brand700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 28),
                        Text(
                          'Elige las alergias de ${widget.personName}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.ink900.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Allergen>(
                          value: _dropdownValue,
                          items: _availableToAdd
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a.name,
                                    style: GoogleFonts.nunito(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _dropdownValue = value),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.ink900,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Selecciona',
                            hintStyle: GoogleFonts.nunito(
                              color: AppColors.ink900.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: AppColors.ink50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _dropdownValue == null
                                ? null
                                : _addSelected,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(23),
                              ),
                            ),
                            child: Text(
                              'Añadir',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.brand50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.brand500,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            'Los productos con estas alergias se marcarán automáticamente en el menú del hijo/a.',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.brand700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              'Guardar cambios',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
