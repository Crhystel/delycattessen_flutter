import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/pin_entry_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../children/providers/children_provider.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import 'payphone_webview_screen.dart';
import 'recharge_card_form_screen.dart';

class ChildOption {
  final int walletId;
  final String name;
  final double currentBalance;
  final String? profilePictureUrl;
  final int? studentId;

  ChildOption({
    required this.walletId,
    required this.name,
    required this.currentBalance,
    this.profilePictureUrl,
    this.studentId,
  });
}

class WalletRechargeScreen extends StatefulWidget {
  /// Opcional: si se pasa, la pantalla usa esta lista fija en vez de leer
  /// del ChildrenProvider (útil si algún día hace falta un flujo con una
  /// selección ya acotada desde afuera).
  final List<ChildOption>? children;
  final int? initialWalletId;

  const WalletRechargeScreen({super.key, this.children, this.initialWalletId});

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen>
    with NotificationMixin {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  int? _selectedWalletId;
  bool _isSubmitting = false;

  static const List<double> _quickAmounts = [5.00, 10.00, 15.00];
  static const double _gatewayThreshold = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedWalletId = widget.initialWalletId;
    if (widget.children == null) {
      Future.microtask(() => context.read<ChildrenProvider>().ensureLoaded());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Hijos con billetera activa, como ChildOption. Si la pantalla recibió
  /// una lista fija por constructor la usa tal cual; si no, la deriva del
  /// ChildrenProvider compartido (sin volver a pedir getChildren()).
  List<ChildOption> _childrenOptions(BuildContext context) {
    if (widget.children != null) return widget.children!;
    final children = context.watch<ChildrenProvider>().children;
    return children
        .where((c) => c.walletId != null)
        .map(
          (c) => ChildOption(
            walletId: c.walletId!,
            name: '${c.firstName} ${c.lastName}',
            currentBalance: c.balance ?? 0,
            profilePictureUrl: c.profilePictureUrl,
            studentId: c.id,
          ),
        )
        .toList();
  }

  ChildOption? _resolveSelectedChild(List<ChildOption> children) {
    if (children.isEmpty) return null;
    return children.firstWhere(
      (c) => c.walletId == _selectedWalletId,
      orElse: () => children.first,
    );
  }

  void _setQuickAmount(double amount) {
    setState(() => _amountController.text = amount.toStringAsFixed(2));
  }

  Future<bool> _confirmWithPin() async {
    final me = await _authService.getMe();
    if (!mounted) return false;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinEntryScreen(
          isCreating: !me.hasPaymentPin,
          onCreate: (pin) => _authService.setPaymentPin(pin),
          onVerify: (pin) => _authService.verifyPaymentPin(pin),
        ),
      ),
    );
    return result == true;
  }

  Future<void> _proceedToRecharge() async {
    final selectedChild = _resolveSelectedChild(_childrenOptions(context));
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showWarningSnackBar(
        'Ingresa un monto válido para recargar.',
        title: 'Monto inválido',
      );
      return;
    }

    if (amount < 1.0) {
      showWarningSnackBar(
        'El monto mínimo de recarga es \$1.00.',
        title: 'Monto muy bajo',
      );
      return;
    }

    if (selectedChild == null) {
      showWarningSnackBar(
        'Debes seleccionar a quién recargar saldo.',
        title: 'Selecciona un hijo',
      );
      return;
    }

    final confirmed = await _confirmWithPin();
    if (!confirmed || !mounted) return;

    if (amount < _gatewayThreshold) {
      await _rechargeViaPayphone(selectedChild, amount);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RechargeCardFormScreen(
            walletId: selectedChild.walletId,
            childName: selectedChild.name,
            amount: amount,
          ),
        ),
      );
    }
  }

  Future<void> _rechargeViaPayphone(
    ChildOption selectedChild,
    double amount,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      final response = await _walletService.recharge(
        RechargeRequest(walletId: selectedChild.walletId, amount: amount),
      );
      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              PayphoneWebViewScreen(paymentUrl: response.paymentUrl!),
        ),
      );
      if (result == true && mounted) {
        showSuccessSnackBar(
          'El saldo se acreditó correctamente.',
          title: '¡Recarga exitosa!',
        );
        if (!mounted) return;
        if (widget.children == null) {
          await context.read<ChildrenProvider>().refresh();
        }
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo procesar la recarga',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = widget.children == null
        ? context.watch<ChildrenProvider>()
        : null;
    final children = _childrenOptions(context);
    final selectedChild = _resolveSelectedChild(children);
    final isLoadingChildren =
        childrenProvider != null &&
        childrenProvider.isLoading &&
        !childrenProvider.hasLoadedOnce;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const FloatingBubbles(corner: BubbleCorner.topRight),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Selecciona a quién recargar',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.ink900.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildChildSelector(
                          children,
                          selectedChild,
                          isLoadingChildren,
                        ),
                        const SizedBox(height: 20),
                        _buildBalanceCard(selectedChild),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Monto a recargar',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAmountField(),
                        const SizedBox(height: 14),
                        _buildQuickAmountChips(),
                        const SizedBox(height: 28),
                        _buildRechargeButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        studentId: selectedChild?.studentId,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          const SizedBox(width: 4),
          Text(
            'Billetera Digital',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(
    List<ChildOption> children,
    ChildOption? selectedChild,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: AppColors.secondary500),
        ),
      );
    }

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No hay hijos con billetera activa.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children.map((child) {
        final isSelected = child.walletId == selectedChild?.walletId;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => setState(() => _selectedWalletId = child.walletId),
            child: Container(
              width: 88,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary500
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.ink50,
                    backgroundImage: child.profilePictureUrl != null
                        ? NetworkImage(child.profilePictureUrl!)
                        : null,
                    child: child.profilePictureUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.secondary500,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    child.name,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.ink900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceCard(ChildOption? selectedChild) {
    final balance = selectedChild?.currentBalance ?? 0.0;
    final childName = selectedChild?.name ?? 'Usuario';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal500,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Saldo Actual de $childName',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink900,
      ),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: GoogleFonts.nunito(
          fontSize: 20,
          color: AppColors.ink900.withValues(alpha: 0.4),
        ),
        hintText: '0.00',
        filled: true,
        fillColor: AppColors.ink50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: _quickAmounts.map((amount) {
        return GestureDetector(
          onTap: () => _setQuickAmount(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brand500),
            ),
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brand700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRechargeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _proceedToRecharge,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_outline, size: 18, color: Colors.white),
        label: Text(
          'Recargar saldo seguro',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
