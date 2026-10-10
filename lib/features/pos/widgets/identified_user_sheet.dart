import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../models/pos_identification_model.dart';
import '../services/pos_service.dart';

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
  final PosService _posService = PosService();
  final Set<int> _deliveredPreOrderIds = {};
  int? _submittingPreOrderId;

  Future<void> _markAsDelivered(int preOrderId) async {
    setState(() => _submittingPreOrderId = preOrderId);
    try {
      await _posService.markPreOrderDelivered(preOrderId);
      if (!mounted) return;
      setState(() {
        _deliveredPreOrderIds.add(preOrderId);
        _submittingPreOrderId = null;
      });
      showSuccessSnackBar(
        'El pedido se marcó como entregado.',
        title: 'Entrega confirmada',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingPreOrderId = null);
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo confirmar la entrega',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.ink900.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: AppColors.success500,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Usuario identificado',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.brand50,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.role} · ${user.institution ?? "Sin institución"}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.teal500,
                      borderRadius: BorderRadius.circular(16),
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
                              'Saldo disponible',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${user.balance.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user.allergies.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildAllergySection(user),
                  ],
                  if (user.pendingOrders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildPendingOrdersSection(user),
                  ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: PrimaryButton(
              label: 'Aceptar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergySection(IdentifiedUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger500, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'ALERGIAS REGISTRADAS',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.allergies
                .map(
                  (allergen) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      allergen,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersSection(IdentifiedUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final preOrder in user.pendingOrders)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPreOrderCard(preOrder),
          ),
      ],
    );
  }

  Widget _buildPreOrderCard(PendingPreOrder preOrder) {
    final isDelivered = _deliveredPreOrderIds.contains(preOrder.preOrderId);
    final isSubmitting = _submittingPreOrderId == preOrder.preOrderId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: AppColors.brand700,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pedido pendiente por entregar',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in preOrder.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand500,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.menuItemName,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isDelivered
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success500,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Entregado',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () => _markAsDelivered(preOrder.preOrderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand500,
                      foregroundColor: AppColors.ink900,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll,
                      ),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink900,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            color: AppColors.ink900,
                            size: 18,
                          ),
                    label: Text(
                      isSubmitting ? 'Confirmando...' : 'Marcar como entregado',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
