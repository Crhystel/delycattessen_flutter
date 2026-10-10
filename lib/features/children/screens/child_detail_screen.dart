import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/photo_source_dialog.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../../menu/screens/transaction_history_screen.dart';
import '../../users/models/allergy_models.dart';
import '../../users/screens/allergy_management_screen.dart';
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
  List<Allergen>? _allergies; // null = cargando o no disponible

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _loadAllergies();
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
        builder: (_) => TransactionHistoryScreen(
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
  }

  void _goToAllergies(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          studentId: _currentChild.id,
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
              decoration: const BoxDecoration(color: AppColors.teal500),
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
                            color: AppColors.secondary500,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.teal700,
                            backgroundImage: child.profilePictureUrl != null
                                ? NetworkImage(child.profilePictureUrl!)
                                : null,
                            child: _isUpdatingPhoto
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : (child.profilePictureUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
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
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.mdAll,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo actual',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${(child.balance ?? 0).toStringAsFixed(2)}',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: 'Recargar saldo',
                        icon: Icons.add,
                        onPressed: () => _goToWallet(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _goToHistory(context),
                          icon: const Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: AppColors.teal500,
                          ),
                          label: const Text(
                            'Ver movimientos',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Control de gastos',
                    subtitle: 'Límite diario y días permitidos',
                    onTap: () => _goToParentalControl(context),
                  ),
                  buildSettingRow(
                    icon: Icons.warning_amber_outlined,
                    title: 'Alergias',
                    subtitle: _allergiesSummary,
                    onTap: () => _goToAllergies(context),
                  ),
                ],
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
