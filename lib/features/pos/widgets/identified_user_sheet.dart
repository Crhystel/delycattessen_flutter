import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../models/pos_identification_model.dart';
import '../providers/preorder_delivery_controller.dart';
import 'amount_card.dart';
import 'pending_preorder_card.dart';
import 'status_card.dart';

/// Acción elegida por el cajero al cerrar la hoja del usuario identificado.
enum IdentifiedUserAction { addProducts }

/// Hoja de confirmación tras identificar al usuario en el POS. Vive como
/// widget aparte de PosHomeScreen (Single Responsibility) porque es una
/// pieza de presentación con su propia composición y su propio estado
/// (confirmar entrega de pedidos pendientes).
class IdentifiedUserSheet extends StatefulWidget {
  final IdentifiedUser user;

  const IdentifiedUserSheet({super.key, required this.user});

  @override
  State<IdentifiedUserSheet> createState() => _IdentifiedUserSheetState();
}

class _IdentifiedUserSheetState extends State<IdentifiedUserSheet>
    with NotificationMixin {
  final _delivery = PreOrderDeliveryController();

  // Solo presentación: tarjetas plegables del diseño del Figma.
  static const int _collapsedAllergyCount = 3;
  bool _showAllAllergies = false;
  bool _showPreOrders = false;

  @override
  void initState() {
    super.initState();
    _delivery.addListener(_onDeliveryChanged);
  }

  @override
  void dispose() {
    _delivery.removeListener(_onDeliveryChanged);
    _delivery.dispose();
    super.dispose();
  }

  void _onDeliveryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _markAsDelivered(int preOrderId) async {
    final error = await _delivery.markAsDelivered(preOrderId);
    if (!mounted) return;
    if (error == null) {
      showSuccessSnackBar(
        'El pedido se marcó como entregado.',
        title: 'Entrega confirmada',
      );
    } else {
      showErrorSnackBar(error, title: 'No se pudo confirmar la entrega');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final screenHeight = MediaQuery.of(context).size.height;
    // El botón "atrás" de Android tampoco cierra la sesión del usuario.
    return PopScope(
      canPop: false,
      child: Container(
        // Pantalla completa como en el Figma (antes era una hoja al 88 %).
        height: screenHeight,
        color: Colors.white,
        child: Column(
          children: [
            _buildGradientHeader(user),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      40 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: ResponsiveCenter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (user.allergies.isNotEmpty) ...[
                            _buildAllergyCard(user),
                            const SizedBox(height: 20),
                          ],
                          if (user.pendingOrders.isNotEmpty) ...[
                            _buildPreOrdersCard(user),
                            const SizedBox(height: 20),
                          ],
                          _buildSuccessCard(),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Método: ${user.identificationMethod == "FACE_RECOGNITION" ? "Reconocimiento facial" : "Código QR"}',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.ink900.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encabezado con degradado azul-morado del Figma: saludo, avatar y monto.
  Widget _buildGradientHeader(IdentifiedUser user) {
    final firstName = user.fullName.trim().isEmpty
        ? user.username
        : user.fullName.trim().split(RegExp(r'\s+')).first;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.teal500, AppColors.secondary500],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 8,
        12,
        56,
      ),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hola $firstName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Terminar la atención de este usuario y volver al inicio del POS.
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Terminar atención',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              '${user.roleDisplay} · ${user.institution ?? "Sin institución"}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildAmountCard(user)),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Monto según el rol: saldo para estudiantes y crédito del mes para
  /// docentes (no usan billetera). Sin dato no se muestra nada, para no
  /// enseñar un $0.00 engañoso.
  Widget _buildAmountCard(IdentifiedUser user) {
    final double? amount = user.isTeacher
        ? user.creditAccumulated
        : user.balance;
    if (amount == null) return const SizedBox.shrink();
    return AmountCard(
      icon: user.isTeacher
          ? Icons.account_balance_outlined
          : Icons.account_balance_wallet_outlined,
      label: user.isTeacher ? 'Crédito del mes' : 'Saldo Actual',
      amount: amount,
    );
  }

  Widget _buildAllergyCard(IdentifiedUser user) {
    final visible = _showAllAllergies
        ? user.allergies
        : user.allergies.take(_collapsedAllergyCount).toList();
    final canExpand = user.allergies.length > _collapsedAllergyCount;
    return StatusCard(
      accent: AppColors.danger500,
      background: AppColors.dangerBg,
      icon: Icons.report_gmailerrorred_rounded,
      title: 'Alergias detectadas',
      subtitle: 'Tienes alergias registradas',
      count: user.allergies.length,
      actionLabel: canExpand
          ? (_showAllAllergies ? 'Ver menos' : 'Ver todas las alergias')
          : null,
      onAction: canExpand
          ? () => setState(() => _showAllAllergies = !_showAllAllergies)
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final allergen in visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.danger500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.danger500.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                allergen,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreOrdersCard(IdentifiedUser user) {
    final count = user.pendingOrders.length;
    return StatusCard(
      accent: AppColors.brand500,
      background: AppColors.brand50,
      icon: Icons.event_available_outlined,
      title: 'Preórdenes',
      subtitle:
          'Tienes $count ${count == 1 ? 'preorden' : 'preórdenes'} para hoy',
      count: count,
      actionLabel: _showPreOrders ? 'Ocultar detalles' : 'Ver detalles',
      onAction: () => setState(() => _showPreOrders = !_showPreOrders),
      child: _showPreOrders
          ? Column(
              children: [
                for (final preOrder in user.pendingOrders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PendingPreOrderCard(
                      preOrder: preOrder,
                      isDelivered: _delivery.isDelivered(preOrder.preOrderId),
                      isSubmitting: _delivery.isSubmitting(preOrder.preOrderId),
                      onDeliver: () => _markAsDelivered(preOrder.preOrderId),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink900.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success500,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identificación exitosa',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success500,
                      ),
                    ),
                    Text(
                      'Puedes continuar para ver los productos',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Ver productos  →',
            onPressed: () =>
                Navigator.of(context).pop(IdentifiedUserAction.addProducts),
          ),
        ],
      ),
    );
  }
}
