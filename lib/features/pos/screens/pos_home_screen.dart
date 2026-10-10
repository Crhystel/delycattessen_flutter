import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/screens/login_screen.dart';
import '../models/pos_identification_model.dart';
import 'face_recognition_scan_screen.dart';
import 'qr_scan_screen.dart';
import '../widgets/identified_user_sheet.dart';

class PosHomeScreen extends StatefulWidget {
  final String userName;
  const PosHomeScreen({super.key, this.userName = 'Usuario'});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> with NotificationMixin {
  String _getCurrentDayFormatted() {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final now = DateTime.now();
    final dayName = days[now.weekday - 1];
    return 'Hoy es $dayName';
  }

  void _onUserIdentified(IdentifiedUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IdentifiedUserSheet(user: user),
    );
  }

  void _navigateToFaceScan() async {
    final result = await Navigator.of(context).push<IdentifiedUser>(
      MaterialPageRoute(builder: (_) => const FaceRecognitionScanScreen()),
    );
    if (result != null && mounted) {
      _onUserIdentified(result);
    }
  }

  void _navigateToQrScan() async {
    final result = await Navigator.of(context).push<IdentifiedUser>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (result != null && mounted) {
      _onUserIdentified(result);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await AppConfirmationDialog.show(
      context,
      icon: Icons.logout_rounded,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas cerrar sesión en el POS?',
      confirmLabel: 'Cerrar sesión',
    );

    if (shouldLogout && mounted) {
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      bubbleCorner: BubbleCorner.topRight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola ${widget.userName}',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _getCurrentDayFormatted(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _confirmLogout,
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.teal700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '¿Cómo identificamos al usuario?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.teal700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecciona el método para identificar al usuario y registrar su consumo.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PosOptionCard(
              iconBackground: AppColors.teal500,
              iconColor: Colors.white,
              icon: Icons.face_retouching_natural_rounded,
              title: 'Reconocimiento facial',
              subtitle: 'Identifica por rostro',
              onTap: _navigateToFaceScan,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PosOptionCard(
              iconBackground: AppColors.brand500,
              iconColor: AppColors.ink900,
              icon: Icons.qr_code_2_rounded,
              title: 'Escanear código QR',
              subtitle: 'Escanea el código QR del usuario',
              onTap: _navigateToQrScan,
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => showInfoSnackBar(
                  'Venta Rápida aún no está implementada.',
                  duration: const Duration(seconds: 2),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal700,
                  minimumSize: const Size(190, 48),
                  side: const BorderSide(color: AppColors.teal500, width: 1.5),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.smAll,
                  ),
                ),
                icon: const Icon(Icons.bolt),
                label: const Text(
                  'Venta rápida',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// Large tappable option used on the cashier home (face or QR identification).
class _PosOptionCard extends StatelessWidget {
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PosOptionCard({
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl - 4),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.teal500),
        ],
      ),
    );
  }
}
