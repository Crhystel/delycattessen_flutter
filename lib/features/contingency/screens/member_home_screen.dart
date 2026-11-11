import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/greeting_text.dart';
import '../../../core/widgets/header_actions.dart';
import '../../../core/widgets/profile_bubble.dart';
import '../../../core/widgets/tab_header.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../menu/screens/member_menu_screen.dart';
import '../../menu/screens/member_products_screen.dart';
import '../../menu/services/product_catalog_source.dart';
import '../../pos/screens/credit_history_screen.dart';
import '../../users/screens/allergy_management_screen.dart';
import '../../users/services/allergy_owner.dart';
import '../models/qr_token_model.dart';
import '../services/qr_service.dart';
import '../widgets/member_shortcut_list.dart';

/// Inicio de estudiantes y docentes: saldo (solo estudiantes), QR dinámico
/// para identificarse en el POS y accesos de solo consulta: el estudiante ve el
/// menú del mes y los productos; el docente, los productos, su crédito y sus
/// alergias.
class MemberHomeScreen extends StatefulWidget {
  final String? initialUserName;
  final bool isTeacher;

  const MemberHomeScreen({
    super.key,
    this.initialUserName,
    this.isTeacher = false,
  });

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen>
    with NotificationMixin {
  final QrService _qrService = QrService();
  QrTokenModel? _qrData;
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _secondsLeft = 300;

  @override
  void initState() {
    super.initState();
    _loadQrToken();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')} min';
    }
    return '${s}s';
  }

  void _startTimer(int totalSeconds) {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = totalSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        _loadQrToken(silent: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _loadQrToken({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _qrService.getDynamicQrToken();
      if (mounted) {
        setState(() {
          _qrData = data;
          _isLoading = false;
        });
        _startTimer(data.expiresIn > 0 ? data.expiresIn : 300);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = errorMessageOf(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Teachers open their profile: names, email, password and their allergies
  /// (students have no profile).
  Future<void> _openProfile() async {
    try {
      final me = await AuthService().getMe();
      if (!mounted) return;
      final updated = await Navigator.of(context).push<MeResponse>(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            me: me,
            onOpenAllergies: _openAllergies,
            onLogout: _confirmLogout,
          ),
        ),
      );
      // The greeting shows the name that comes with the QR data.
      if (updated != null && mounted) _loadQrToken();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo abrir tu perfil');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: Icons.logout,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas salir de tu cuenta?',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
    );
    if (confirmed) {
      await AuthService().logout();
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
    final displayName = _qrData?.fullName.isNotEmpty == true
        ? _qrData!.fullName
        : (widget.initialUserName ?? 'Usuario');
    final balanceText = _qrData != null
        ? '\$${_qrData!.balance.toStringAsFixed(2)}'
        : '\$0.00';

    return AppScaffold(
      // TabHeader calcula su propio margen superior (la burbuja o el botón de
      // cerrar sesión quedan a la misma altura que en las pestañas del padre).
      safeAreaTop: false,
      bubbleCorners: const [
        BubbleCorner.topRight,
        BubbleCorner.homeBottomLeft,
        BubbleCorner.homeBottomRight,
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(displayName),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildContent(textTheme, balanceText),
            ),
          ],
        ),
      ),
    );
  }

  /// Una sola fila para ambos roles: el saludo a la izquierda y, a la derecha,
  /// la burbuja de perfil del docente (cerrar sesión está dentro de "Mi
  /// perfil") o, para el estudiante (sin perfil), solo cerrar sesión sobre una
  /// píldora blanca para que se lea sobre las burbujas.
  Widget _buildHeader(String displayName) {
    return TabHeader(
      leading: GreetingText(name: displayName),
      trailing: widget.isTeacher
          ? ProfileBubble(
              initial: displayName.trim().isEmpty
                  ? ''
                  : displayName.trim().substring(0, 1),
              onTap: _openProfile,
            )
          : HeaderActions(
              actions: [
                HeaderAction(
                  icon: Icons.logout,
                  tooltip: 'Cerrar sesión',
                  onPressed: _confirmLogout,
                  color: AppColors.danger700,
                ),
              ],
            ),
    );
  }

  Widget _buildContent(TextTheme textTheme, String balanceText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance card with Figma gradient (docentes no usan billetera)
        if (!widget.isTeacher) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl - 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0068D6), // Vibrant Blue
                  Color(0xFF4F46E5), // Indigo / Purple
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Saldo actual',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  balanceText,
                  style: textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        MemberShortcutList(shortcuts: _shortcuts()),
        const SizedBox(height: AppSpacing.xl),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFE5A93C),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Tu código QR',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFE5A93C),
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // White card with the dynamic QR (always black on white to scan)
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl - 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildQrContent(textTheme),
          ),
        ),
        const SizedBox(height: AppSpacing.xl - 4),

        // Security badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md - 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.warning500.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.warning700,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Este código es único y personal.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.warning700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Espacio para que el contenido no quede bajo las burbujas inferiores.
        const SizedBox(height: AppSpacing.xxl * 3),
      ],
    );
  }

  void _openCreditHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreditHistoryScreen(
          personName: _qrData?.fullName.isNotEmpty == true
              ? _qrData!.fullName
              : (widget.initialUserName ?? 'Docente'),
        ),
      ),
    );
  }

  void _openMenu() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MemberMenuScreen()));
  }

  void _openProducts() {
    final source = widget.isTeacher
        ? OwnCatalogSource.teacher()
        : OwnCatalogSource.student();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MemberProductsScreen(source: source)),
    );
  }

  void _openAllergies() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          owner: TeacherAllergyOwner(),
          personName: widget.initialUserName ?? 'Docente',
        ),
      ),
    );
  }

  /// Accesos de solo consulta según el rol. El estudiante ve el menú del mes
  /// (no existe para docentes) y los productos; el docente, los productos y su
  /// crédito.
  List<MemberShortcut> _shortcuts() {
    final products = MemberShortcut(
      icon: Icons.storefront_outlined,
      label: 'Catálogo de productos',
      onTap: _openProducts,
    );
    if (widget.isTeacher) {
      return [
        products,
        MemberShortcut(
          icon: Icons.account_balance_outlined,
          label: 'Mi crédito',
          onTap: _openCreditHistory,
        ),
      ];
    }
    return [
      MemberShortcut(
        icon: Icons.restaurant_menu_outlined,
        label: 'Menú del mes',
        onTap: _openMenu,
      ),
      products,
    ];
  }

  Widget _buildQrContent(TextTheme textTheme) {
    if (_isLoading) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary500),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger500,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _loadQrToken(),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        QrImageView(
          data: _qrData!.token,
          version: QrVersions.auto,
          size: 190.0,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Se actualiza en ${_formatTimer(_secondsLeft)}',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink900.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
