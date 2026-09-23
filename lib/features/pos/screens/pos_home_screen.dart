import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/screens/login_screen.dart';
import '../models/pos_identification_model.dart';
import 'face_recognition_scan_screen.dart';
import 'qr_scan_screen.dart';

class PosHomeScreen extends StatefulWidget {
  final String userName;
  const PosHomeScreen({super.key, this.userName = 'Usuario'});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  String _getCurrentDayFormatted() {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    final now = DateTime.now();
    final dayName = days[now.weekday - 1];
    return 'Hoy es $dayName';
  }

  void _onUserIdentified(IdentifiedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.success500, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Usuario Identificado',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rol: ${user.role}  •  ${user.institution ?? "Sin institución"}',
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo disponible:',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal700,
                    ),
                  ),
                  Text(
                    '\$${user.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal700,
                    ),
                  ),
                ],
              ),
            ),
            if (user.allergies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger500, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alérgenos: ${user.allergies.join(", ")}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Método: ${user.identificationMethod == "FACE_RECOGNITION" ? "Reconocimiento Facial" : "Código QR"}',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Aceptar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFaceScan() async {
    final result = await Navigator.of(context).push<IdentifiedUser>(
      MaterialPageRoute(
        builder: (_) => const FaceRecognitionScanScreen(),
      ),
    );
    if (result != null && mounted) {
      _onUserIdentified(result);
    }
  }

  void _navigateToQrScan() async {
    final result = await Navigator.of(context).push<IdentifiedUser>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(),
      ),
    );
    if (result != null && mounted) {
      _onUserIdentified(result);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger500, size: 26),
            const SizedBox(width: 10),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión en el POS?',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth / 402.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            // Top Decorative Shapes (Figma: FloatingBubbles top-right)
            const FloatingBubbles(corner: BubbleCorner.topRight),

            // Bottom Decorative Shapes (Figma: Blue & Amber overlapping gentle domes pinned to bottom)
            Positioned(
              bottom: -110 * scale,
              left: -35 * scale,
              child: Container(
                width: 155 * scale,
                height: 155 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFF007ACC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -105 * scale,
              left: 65 * scale,
              child: Container(
                width: 150 * scale,
                height: 150 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8A020),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -95 * scale,
              left: 155 * scale,
              child: Container(
                width: 155 * scale,
                height: 155 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFF007ACC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -105 * scale,
              right: -35 * scale,
              child: Container(
                width: 155 * scale,
                height: 155 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8A020),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                  // Greetings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola ${widget.userName}',
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getCurrentDayFormatted(),
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _confirmLogout,
                        tooltip: 'Cerrar sesión',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger500,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Instruction Subheading
                  Text(
                    'Selecciona el método para identificar al usuario y registrar su consumo.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Card 1: Reconocimiento Facial (Figma: 304 x 169)
                  Center(
                    child: _buildOptionCard(
                      width: 304 * scale,
                      height: 169 * scale,
                      iconBgColor: const Color(0xFF5932EA), // Vibrant purple
                      icon: Icons.face_retouching_natural_rounded,
                      title: 'Reconocimiento\nFacial',
                      titleColor: const Color(0xFF5932EA),
                      subtitle: 'Identifica por rostro',
                      onTap: _navigateToFaceScan,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card 2: Escanear Código QR (Figma: 304 x 169)
                  Center(
                    child: _buildOptionCard(
                      width: 304 * scale,
                      height: 169 * scale,
                      iconBgColor: const Color(0xFFE5A93C), // Amber
                      icon: Icons.qr_code_2_rounded,
                      title: 'Escanear Código\nQR',
                      titleColor: const Color(0xFFE5A93C),
                      subtitle: 'Escanea el código QR del usuario',
                      onTap: _navigateToQrScan,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Button: Venta Rápida (Figma)
                  Center(
                    child: Container(
                      width: 190,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5932EA), // Purple from Figma
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Venta Rápida aún no está implementada.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Venta Rápida',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildOptionCard({
    required double width,
    required double height,
    required Color iconBgColor,
    required IconData icon,
    required String title,
    required Color titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4D4D8), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Box (Figma style)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),

                // Texts
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD4D4D8),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
