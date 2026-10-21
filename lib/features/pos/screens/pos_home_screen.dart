import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
import '../screens/pos_menu_screen.dart';

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

  Future<void> _onUserIdentified(IdentifiedUser user) async {
    final action = await showModalBottomSheet<IdentifiedUserAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Es la "sesión" del usuario identificado: solo se sale con el botón
      // de cerrar sesión o con "Ver productos", no deslizando ni tocando fuera.
      enableDrag: false,
      isDismissible: false,
      builder: (ctx) => IdentifiedUserSheet(user: user),
    );
    if (action == IdentifiedUserAction.addProducts && mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PosMenuScreen(user: user)));
    }
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

  /// Escala de textos y tarjetas: en tablet el cajero trabaja a cierta
  /// distancia, así que todo se ve más grande y claro.
  double get _scale => AppLayout.isTablet(context) ? 1.7 : 1.0;

  Widget _buildOptions() {
    final faceCard = _PosOptionCard(
      iconBackground: const Color(0xFF5932EA),
      iconColor: Colors.white,
      icon: Icons.face_retouching_natural_rounded,
      title: 'Reconocimiento\nFacial',
      titleColor: const Color(0xFF5932EA),
      subtitle: 'Identifica por rostro',
      onTap: _navigateToFaceScan,
      scale: _scale,
    );
    final qrCard = _PosOptionCard(
      iconBackground: const Color(0xFFE5A93C),
      iconColor: Colors.white,
      icon: Icons.qr_code_2_rounded,
      title: 'Escanear Código\nQR',
      titleColor: const Color(0xFFE5A93C),
      subtitle: 'Escanea el código QR del usuario',
      onTap: _navigateToQrScan,
      scale: _scale,
    );
    final isLandscapeTablet =
        AppLayout.isTablet(context) &&
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Teléfono y tablet vertical: una debajo de la otra, a todo el ancho.
    // Tablet horizontal: lado a lado.
    if (!isLandscapeTablet) {
      return Column(
        children: [
          faceCard,
          SizedBox(height: AppSpacing.lg * _scale),
          qrCard,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: faceCard),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: qrCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = _scale;

    return AppScaffold(
      bubbleCorner: BubbleCorner.topRight,
      maxContentWidth: AppLayout.wideMaxWidth,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl * (s > 1 ? 1.5 : 1)),
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
                          fontSize: 24 * s,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _getCurrentDayFormatted(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.65),
                          fontSize: 14 * s,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _confirmLogout,
                  tooltip: 'Cerrar sesión',
                  iconSize: 24 * s,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.teal700,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl * s),
            Text(
              '¿Cómo identificamos al usuario?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.teal700,
                fontSize: 22 * s,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecciona el método para identificar al usuario y registrar su consumo.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.6),
                fontSize: 14 * s,
              ),
            ),
            SizedBox(height: AppSpacing.xl * s),
            _buildOptions(),
            SizedBox(height: AppSpacing.xl * s),
            Center(
              child: Container(
                width: 190 * s,
                height: 48 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFF5932EA),
                  borderRadius: BorderRadius.circular(12 * s),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12 * s),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PosMenuScreen()),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 20 * s),
                        SizedBox(width: 6 * s),
                        Text(
                          'Venta Rápida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
/// [scale] enlarges paddings, icon and text on tablets.
class _PosOptionCard extends StatelessWidget {
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final String title;
  final Color titleColor;
  final String subtitle;
  final VoidCallback onTap;
  final double scale;

  const _PosOptionCard({
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      width: double.infinity,
      // En teléfono se mantiene el ancho del Figma; en tablet ocupa el ancho.
      constraints: BoxConstraints(maxWidth: s > 1 ? double.infinity : 340),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: const Color(0xFFD4D4D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20 * s),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * s,
              vertical: 20 * s * (s > 1 ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 58 * s,
                  height: 58 * s,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(16 * s),
                  ),
                  child: Icon(icon, color: iconColor, size: 32 * s),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17 * s,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12 * s,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFFD4D4D8),
                  size: 26 * s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
