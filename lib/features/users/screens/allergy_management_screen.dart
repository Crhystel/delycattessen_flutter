import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../models/allergy_models.dart';
import '../../auth/services/auth_service.dart';

class AllergyManagementScreen extends StatefulWidget {
  final int targetUserId;
  final String personName;

  const AllergyManagementScreen({
    super.key,
    required this.targetUserId,
    required this.personName,
  });

  @override
  State<AllergyManagementScreen> createState() =>
      _AllergyManagementScreenState();
}

class _AllergyManagementScreenState extends State<AllergyManagementScreen> {
  final _authService = AuthService();
  List<Allergen> _allAllergens = [];
  Set<int> _selectedIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allergens = await _authService.getAllergens();
      final selected = await _authService.getUserAllergyIds(
        widget.targetUserId,
      );
      setState(() {
        _allAllergens = allergens;
        _selectedIds = selected.toSet();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _authService.saveUserAllergies(
        widget.targetUserId,
        _selectedIds.toList(),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink900),
        title: Text(
          'Alergias',
          style: GoogleFonts.nunito(
            color: AppColors.ink900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary500),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Alergias registradas para ${widget.personName}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    children: _allAllergens.map((allergen) {
                      final isSelected = _selectedIds.contains(allergen.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(allergen.id);
                            } else {
                              _selectedIds.remove(allergen.id);
                            }
                          });
                        },
                        activeColor: AppColors.secondary500,
                        title: Text(
                          allergen.name,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: AppColors.ink900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Guardar',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
