import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/photo_source_dialog.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../../menu/screens/transaction_history_screen.dart';
import '../../users/models/allergy_models.dart';
import '../../users/screens/allergy_management_screen.dart';
import '../../users/services/allergy_owner.dart';
import '../models/parental_control_model.dart';
import '../services/parental_control_service.dart';
import 'parental_control_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with NotificationMixin {
  late Child _currentChild;
  bool _isUpdatingPhoto = false;
  bool _hasUpdatedPhoto = false;
  final AuthService _authService = AuthService();
  final ParentalControlService _parentalService = ParentalControlService();
  List<Allergen>? _allergies; // null = cargando o no disponible
  ParentalControl? _parentalControl; // null = cargando o no disponible

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _loadAllergies();
    _loadParentalControl();
  }

  Future<void> _loadAllergies() async {
    try {
      final allergies = await _authService.getStudentAllergies(
        _currentChild.id,
      );
      if (!mounted) return;
      setState(() => _allergies = allergies);
    } catch (_) {
      // El resumen es informativo; si falla se muestra el texto genérico.
    }
  }

  Future<void> _loadParentalControl() async {
    try {
      final control = await _parentalService.getParentalControl(
        _currentChild.id,
      );
      if (!mounted) return;
      setState(() => _parentalControl = control);
    } catch (_) {
      // Resumen informativo: si falla se muestra el texto genérico.
    }
  }

  /// Una sola línea con lo que está activo, p. ej. "Límite $5.00/día · Lun, Mié".
  String get _spendingControlSummary {
    final control = _parentalControl;
    if (control == null) return 'Límite diario y días permitidos';

    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final parts = <String>[];
    if (control.dailyLimitEnabled) {
      parts.add('Límite \$${control.dailyLimitAmount.toStringAsFixed(2)}/día');
    }
    if (control.allowedDaysEnabled) {
      final days = ([...control.allowedDays]..sort())
          .where((d) => d >= 0 && d < dayNames.length)
          .map((d) => dayNames[d])
          .toList();
      parts.add(days.isEmpty ? 'Ningún día permitido' : days.join(', '));
    }
    return parts.isEmpty ? 'Sin restricciones' : parts.join(' · ');
  }

  String get _allergiesSummary {
    final allergies = _allergies;
    if (allergies == null) return 'Toca para ver o editar';
    if (allergies.isEmpty) return 'Sin alergias registradas';
    return allergies.map((a) => a.name).join(', ');
  }

  void _goToHistory(BuildContext context) {
    final walletId = _currentChild.walletId;
    if (walletId == null) {
      showWarningSnackBar('Este hijo aún no tiene billetera activa.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen.forWallet(
          walletId: walletId,
          childName: '${_currentChild.firstName} ${_currentChild.lastName}',
        ),
      ),
    );
  }

  void _goToWallet(BuildContext context) async {
    if (_currentChild.walletId == null) {
      showWarningSnackBar('Este hijo aún no tiene billetera activa.');
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WalletRechargeScreen(initialWalletId: _currentChild.walletId!),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _goToParentalControl(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentalControlScreen(studentId: _currentChild.id),
      ),
    );
    if (!mounted) return;
    _loadParentalControl(); // refresca el resumen con lo que se acaba de guardar
  }

  void _goToAllergies(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          owner: StudentAllergyOwner(_currentChild.id),
          personName: '${_currentChild.firstName} ${_currentChild.lastName}',
        ),
      ),
    );
    if (!mounted) return;
    _loadAllergies();
    if (result == true && context.mounted) {
      Navigator.of(
        context,
      ).pop(true); // avisa a ChildrenListScreen que refresque
    }
  }

  Future<void> _updateProfilePicture() async {
    final photo = await PhotoSourceDialog.show(
      context,
      title: 'Foto de ${_currentChild.firstName}',
    );
    if (photo == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      final updated = await _authService.updateChildPhoto(
        _currentChild.id,
        photo.path,
      );
      if (!mounted) return;
      setState(() {
        _currentChild = updated;
        _isUpdatingPhoto = false;
        _hasUpdatedPhoto = true;
      });
      showSuccessSnackBar(
        'La foto de perfil y el reconocimiento facial se han actualizado con éxito.',
        title: 'Foto actualizada',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPhoto = false);
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Error al actualizar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _currentChild;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 46,
              ),
              decoration: const BoxDecoration(color: AppColors.secondary500),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () =>
                          Navigator.of(context).pop(_hasUpdatedPhoto),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isUpdatingPhoto ? null : _updateProfilePicture,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.ink50,
                            backgroundImage: child.profilePictureUrl != null
                                ? ResizeImage(
                                    CachedNetworkImageProvider(
                                      child.profilePictureUrl!,
                                    ),
                                    width: AppImageCacheHelper.cacheSize(
                                      context,
                                      80,
                                    ),
                                    height: AppImageCacheHelper.cacheSize(
                                      context,
                                      80,
                                    ),
                                  )
                                : null,
                            child: _isUpdatingPhoto
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondary500,
                                    ),
                                  )
                                : (child.profilePictureUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.secondary500,
                                          size: 40,
                                        )
                                      : null),
                          ),
                        ),
                        if (!_isUpdatingPhoto)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.brand500,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: AppColors.ink900,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${child.firstName} ${child.lastName}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.institutionName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveCenter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.teal500,
                      borderRadius: AppRadius.mdAll,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Saldo Actual',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${(child.balance ?? 0).toStringAsFixed(2)}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _goToWallet(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.teal500,
                              size: 18,
                            ),
                            label: const Text(
                              'Recargar saldo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () => _goToHistory(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 16,
                                  color: AppColors.ink900,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ver historial de movimientos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.ink900,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    buildSettingRow(
                      icon: Icons.shield_outlined,
                      title: 'Control parental',
                      subtitle: _spendingControlSummary,
                      onTap: () => _goToParentalControl(context),
                    ),
                    buildSettingRow(
                      icon: Icons.warning_amber_outlined,
                      title: 'Alergias registradas',
                      subtitle: _allergiesSummary,
                      onTap: () => _goToAllergies(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary500, size: 22),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.teal500, size: 20),
        ],
      ),
    );
  }
}
