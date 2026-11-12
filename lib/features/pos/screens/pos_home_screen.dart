import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/greeting_text.dart';
import '../../../core/widgets/header_actions.dart';
import '../../../core/widgets/tab_header.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../models/pos_identification_model.dart';
import '../utils/pos_home_layout.dart';
import '../widgets/pos_option_card.dart';
import '../widgets/pos_quick_sale_button.dart';
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
  final _authService = AuthService();

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
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHeader(PosHomeMetrics m) {
    return TabHeader(
      horizontalPadding: m.sideMargin,
      leading: GreetingText(name: widget.userName, scale: m.greetingScale),
      trailing: HeaderActions(
        actions: [
          HeaderAction(
            icon: Icons.logout_rounded,
            tooltip: 'Cerrar sesión',
            onPressed: _confirmLogout,
            color: AppColors.danger700,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(PosHomeMetrics m) {
    final align = m.stacked ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: m.stacked
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo identificas al cliente?',
          textAlign: align,
          style: AppText.sectionTitle.copyWith(fontSize: m.titleSize),
        ),
        const SizedBox(height: 4),
        Text(
          'Toca una opción para empezar a cobrar.',
          textAlign: align,
          style: AppText.secondary.copyWith(fontSize: m.subtitleSize),
        ),
      ],
    );
  }

  Widget _buildOptions(PosHomeMetrics m) {
    final face = PosOptionCard(
      metrics: m,
      icon: Icons.face_retouching_natural_rounded,
      iconBackground: AppColors.secondary500,
      title: 'Reconocimiento facial',
      titleColor: AppColors.secondary500,
      subtitle: 'Identifica por rostro',
      onTap: _navigateToFaceScan,
    );
    final qr = PosOptionCard(
      metrics: m,
      icon: Icons.qr_code_2_rounded,
      iconBackground: AppColors.brand500,
      title: 'Escanear código QR',
      titleColor: AppColors.brand700,
      subtitle: 'Escanea el código QR del usuario',
      onTap: _navigateToQrScan,
    );
    if (!m.stacked) {
      return Column(
        children: [
          face,
          SizedBox(height: m.cardGap),
          qr,
        ],
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: m.gridMaxWidth),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: face),
            SizedBox(width: m.cardGap),
            Expanded(child: qr),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSale(PosHomeMetrics m) {
    final label = Text(
      '¿Sin identificar al cliente?',
      textAlign: TextAlign.center,
      style: AppText.secondary.copyWith(fontSize: m.labelSize),
    );
    final button = PosQuickSaleButton(
      metrics: m,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PosMenuScreen())),
    );
    if (m.quickSaleInline) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg - 2,
        runSpacing: AppSpacing.md,
        children: [label, button],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(height: AppSpacing.sm),
        button,
      ],
    );
  }

  Widget _buildBody(PosHomeMetrics m) {
    if (!m.stacked) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          m.sideMargin,
          PosHomeMetrics.phoneTitleTop,
          m.sideMargin,
          m.bottomMargin,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(m),
              const SizedBox(height: AppSpacing.page),
              _buildOptions(m),
              const SizedBox(height: AppSpacing.xl),
              _buildQuickSale(m),
            ],
          ),
        ),
      );
    }
    final landscape = m.quickSaleInline;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.sideMargin,
        0,
        m.sideMargin,
        m.bottomMargin,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(m),
            SizedBox(height: landscape ? AppSpacing.xxl : 36),
            _buildOptions(m),
            SizedBox(height: landscape ? 28 : 36),
            _buildQuickSale(m),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = PosHomeVariant.fromSize(MediaQuery.sizeOf(context));
    final m = PosHomeMetrics.of(variant);

    return AppScaffold(
      backgroundColor: AppColors.ink50,
      // The header works out its own top margin, like the rest of the redesign.
      safeAreaTop: false,
      bubblesDesign: true,
      bubblesLarge: variant.isTablet,
      bubbleCorners: [
        BubbleCorner.topRight,
        if (variant.isTablet) BubbleCorner.bottomLeft,
      ],
      maxContentWidth: AppLayout.wideMaxWidth,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(m)),
          SliverFillRemaining(hasScrollBody: false, child: _buildBody(m)),
        ],
      ),
    );
  }
}
