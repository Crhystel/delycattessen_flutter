import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/primary_button.dart';
import '../../menu/utils/cart_rules.dart';
import '../../menu/widgets/cart_line_tile.dart';
import '../models/pos_identification_model.dart';
import '../models/sale_models.dart';
import '../providers/pos_cart_controller.dart';
import '../services/pos_service.dart';
import '../utils/payment_method_policy.dart';
import '../widgets/pos_sale_success_sheet.dart';
import '../../../core/utils/error_message.dart';

/// Último paso del POS: elegir método de pago y cobrar. El total que se ve
/// es informativo; el servidor recalcula con los precios de la base de datos.
/// [user] nulo = venta rápida (solo efectivo). [cart] is the menu's cart:
/// edits here are seen by the menu when going back.
class PosCheckoutScreen extends StatefulWidget {
  final IdentifiedUser? user;
  final PosCartController cart;

  const PosCheckoutScreen({super.key, required this.cart, this.user});

  @override
  State<PosCheckoutScreen> createState() => _PosCheckoutScreenState();
}

class _PosCheckoutScreenState extends State<PosCheckoutScreen>
    with NotificationMixin {
  final PosService _posService = PosService();
  late final List<PaymentMethodOption> _options;
  late PaymentMethod _method;
  bool _isSubmitting = false;

  PosCartController get _cart => widget.cart;

  double get _total => _cart.total;

  bool get _walletShort =>
      _method == PaymentMethod.wallet &&
      widget.user != null &&
      widget.user!.balance < _total;

  @override
  void initState() {
    super.initState();
    _options = PaymentMethodPolicy.availableFor(widget.user);
    _method = PaymentMethodPolicy.defaultFor(widget.user);
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    // Removing the last line goes back to the menu.
    if (_cart.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  void _changeQuantity(PosCartLine line, int delta) {
    if (_isSubmitting) return;
    final short = _cart.changeLine(line, delta);
    if (short != null) {
      showWarningSnackBar(
        'No hay unidades suficientes de "$short".',
        title: 'Stock insuficiente',
      );
    }
  }

  void _removeLine(PosCartLine line) {
    if (!_isSubmitting) _cart.removeLine(line);
  }

  Future<void> _charge() async {
    if (_isSubmitting) return;
    final option = PaymentMethodPolicy.optionFor(_method);
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Confirmar cobro',
      message:
          'Se cobrarán \$${_total.toStringAsFixed(2)} con ${option?.label ?? 'el método elegido'}.',
      confirmLabel: 'Cobrar',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final sale = await _posService.createSale(
        _cart.toSaleRequest(_method, userId: widget.user?.userId),
      );
      if (!mounted) return;
      await PosSaleSuccessSheet.show(
        context,
        sale: sale,
        method: _method,
        customerName: widget.user?.fullName,
      );
      if (!mounted) return;
      // El POS es la raíz tras el login: se vuelve al inicio para otra venta.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo cobrar');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lines = _cart.lines;
    final canRemove = CartRules.canRemoveLine(lines.length);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTheme.lightAppBar(title: const Text('Cobrar')),
      body: ResponsiveCenter(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildCustomerBanner(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Resumen',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final line in lines)
                      CartLineTile(
                        name: line.name,
                        unitPrice: line.unitPrice,
                        quantity: line.quantity,
                        onIncrement: () => _changeQuantity(line, 1),
                        onDecrement: () => _changeQuantity(line, -1),
                        onRemove: canRemove ? () => _removeLine(line) : null,
                      ),
                    const Divider(height: AppSpacing.xl),
                    _buildTotal(textTheme),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Método de pago',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final option in _options)
                      _buildOption(option, textTheme),
                    if (_walletShort) _buildBalanceWarning(textTheme),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: 'Cobrar \$${_total.toStringAsFixed(2)}',
                  isLoading: _isSubmitting,
                  onPressed: _options.isEmpty ? null : _charge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerBanner(TextTheme textTheme) {
    final user = widget.user;
    final hasAllergies = user != null && user.allergies.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasAllergies ? AppColors.dangerBg : AppColors.secondary50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        user == null
            ? 'Venta rápida · solo efectivo'
            : 'Cliente: ${user.fullName}',
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink900,
        ),
      ),
    );
  }

  Widget _buildTotal(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          '\$${_total.toStringAsFixed(2)}',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brand700,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(PaymentMethodOption option, TextTheme textTheme) {
    final selected = option.method == _method;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: _isSubmitting
          ? null
          : () => setState(() => _method = option.method),
      child: Row(
        children: [
          Icon(
            option.icon,
            color: selected ? AppColors.secondary500 : AppColors.ink900,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  option.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? AppColors.secondary500 : AppColors.ink900,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceWarning(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.danger700,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Saldo disponible \$${widget.user!.balance.toStringAsFixed(2)}: '
              'puede no alcanzar para este total.',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.danger700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
