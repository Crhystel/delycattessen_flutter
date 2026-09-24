import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/photo_source_dialog.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../../menu/screens/transaction_history_screen.dart';
import '../../users/screens/allergy_management_screen.dart';
import 'parental_control_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;
  final List<Child> allChildren;

  const ChildDetailScreen({
    super.key,
    required this.child,
    required this.allChildren,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late Child _currentChild;
  bool _isUpdatingPhoto = false;
  bool _hasUpdatedPhoto = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
  }
  void _goToWallet(BuildContext context) async {
    final withWallet = widget.allChildren
        .where((c) => c.walletId != null)
        .toList();
    if (widget.child.walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este hijo aún no tiene billetera activa.'),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WalletRechargeScreen(
          children: withWallet
              .map(
                (c) => ChildOption(
                  walletId: c.walletId!,
                  name: '${c.firstName} ${c.lastName}',
                  currentBalance: c.balance ?? 0,
                  profilePictureUrl: c.profilePictureUrl,
                ),
              )
              .toList(),
          initialWalletId: widget.child.walletId!,
        ),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

void _goToParentalControl(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentalControlScreen(
          studentId: widget.child.id,
        ),
      ),
    );
  }

  void _goToAllergies(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          studentId: widget.child.id,
          personName: '${widget.child.firstName} ${widget.child.lastName}',
        ),
      ),
    );
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
      final updated =
          await _authService.updateChildPhoto(_currentChild.id, photo.path);
      if (!mounted) return;
      setState(() {
        _currentChild = updated;
        _isUpdatingPhoto = false;
        _hasUpdatedPhoto = true;
      });
      AppNotificationDialog.show(
        context,
        type: NotificationType.success,
        title: 'Foto actualizada',
        message:
            'La foto de perfil y el reconocimiento facial se han actualizado con éxito.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPhoto = false);
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'Error al actualizar',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _currentChild;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 40,
                ),
                decoration: const BoxDecoration(color: AppColors.secondary500),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(_hasUpdatedPhoto),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isUpdatingPhoto ? null : _updateProfilePicture,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white24,
                            backgroundImage: child.profilePictureUrl != null
                                ? NetworkImage(child.profilePictureUrl!)
                                : null,
                            child: child.profilePictureUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 46,
                                  )
                                : null,
                          ),
                          if (_isUpdatingPhoto)
                            Container(
                              width: 92,
                              height: 92,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8A020),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _isUpdatingPhoto ? null : _updateProfilePicture,
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 14),
                      label: Text(
                        'Cambiar foto de perfil',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${child.firstName} ${child.lastName}',
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child.institutionName,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    borderRadius: BorderRadius.circular(16),
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
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(child.balance ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          label: Text(
                            'Recargar saldo',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TransactionHistoryScreen(
                              walletId: child.walletId!,
                              childName: '${child.firstName} ${child.lastName}',
                            ),
                          ),
                        ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: AppColors.ink900,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ver historial de movimientos',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Límite de gasto diario',
                    subtitle: 'Toca para configurar',
                    onTap: () => _goToParentalControl(context),
                  ),
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Días permitidos de gasto',
                    subtitle: 'Toca para configurar',
                    onTap: () => _goToParentalControl(context),
                  ),
                  _buildSettingRow(
                    icon: Icons.warning_amber_outlined,
                    title: 'Alergias registradas',
                    subtitle: 'Toca para registrar o editar',
                    onTap: () => _goToAllergies(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary500, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              onTap != null ? Icons.chevron_right : Icons.settings_outlined,
              color: const Color(0xFFBBBBBB),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
