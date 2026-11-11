import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../../core/widgets/tab_header.dart';
import 'pin_entry_screen.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_switch_bar.dart';
import '../services/wallet_service.dart';
import '../utils/recharge_launcher.dart';
import '../widgets/recharge_amount_input.dart';
import '../widgets/recharge_balance_card.dart';
import '../widgets/recharge_submit_button.dart';
import '../../../core/utils/error_message.dart';
import 'transaction_history_screen.dart';

/// Secciones de la pestaña Billetera del padre.
enum WalletSection { recharge, movements }

/// Pestaña Billetera del padre: "Recargar" y "Movimientos" del hijo elegido en
/// la barra (el mismo hijo seleccionado que usan Menú y Pedidos).
class WalletRechargeScreen extends StatefulWidget {
  /// Burbuja de perfil a la derecha del título (la pone el ParentShell).
  final Widget? profileAction;

  /// Sección con la que abre la pestaña: Recargar, o Movimientos cuando otra
  /// pantalla (ficha del hijo, detalle de pedido) redirige al historial.
  final WalletSection initialSection;

  const WalletRechargeScreen({
    super.key,
    this.profileAction,
    this.initialSection = WalletSection.recharge,
  });

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen>
    with NotificationMixin {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  late WalletSection _tab = widget.initialSection;

  /// Movimientos se crea al abrirlo por primera vez y luego se conserva.
  late bool _movementsOpened = _tab == WalletSection.movements;

  /// Sube tras cada recarga acreditada: Movimientos vuelve a pedir su lista.
  int _movementsRevision = 0;

  static const List<double> _quickAmounts = [5.00, 10.00, 15.00, 20.00];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChildrenProvider>();
    Future.microtask(provider.ensureLoaded);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _enteredAmount => double.tryParse(_amountController.text);

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
    if (_isSubmitting) return;
    final child = context.read<ChildrenProvider>().selectedChild;
    final walletId = child?.walletId;
    final amount = _enteredAmount;
    if (amount == null || amount <= 0) {
      showWarningSnackBar(
        'Ingresa un monto válido para recargar.',
        title: 'Monto inválido',
      );
      return;
    }

    if (child == null || walletId == null) {
      showWarningSnackBar(
        'Este hijo aún no tiene billetera activa.',
        title: 'Sin billetera',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final confirmed = await _confirmWithPin();
      if (!confirmed || !mounted) return;

      // El servidor decide la pasarela y valida el monto mínimo.
      final gateway = await _walletService.getRechargeGateway(amount);
      if (!mounted) return;
      final credited = await RechargeLaunchers.forGateway(gateway).start(
        context,
        RechargeRequestData(
          walletId: walletId,
          childName: child.displayName,
          amount: amount,
        ),
      );
      if (credited && mounted) await _finishRecharge(amount);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        errorMessageOf(e),
        title: 'No se pudo procesar la recarga',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Cierre común a todas las pasarelas: aviso y saldos al día. La pestaña no
  /// se cierra; solo se limpia el monto.
  Future<void> _finishRecharge(double amount) async {
    showSuccessSnackBar(
      'Tu recarga de \$${amount.toStringAsFixed(2)} se acreditó correctamente.',
      title: '¡Recarga exitosa!',
    );
    await context.read<ChildrenProvider>().refresh();
    if (!mounted) return;
    setState(() {
      _amountController.clear();
      _movementsRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildrenProvider>();
    final child = provider.selectedChild;
    final isLoadingChildren = provider.isLoading && !provider.hasLoadedOnce;

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          // Las burbujas no cambian: se pintan una sola vez en su propia capa.
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topRight, design: true),
          ),
          ResponsiveCenter(
            // El margen superior lo da la cabecera con el inset real del
            // dispositivo (la app dibuja de borde a borde).
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  TabHeader(
                    leading: Text('Billetera', style: AppText.tabTitle),
                    trailing: widget.profileAction,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      0,
                    ),
                    child: SegmentedSwitch<WalletSection>(
                      palette: SegmentedSwitchPalette.blue,
                      options: const [
                        (WalletSection.recharge, 'Recargar'),
                        (WalletSection.movements, 'Movimientos'),
                      ],
                      selected: _tab,
                      onChanged: _onTabChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      14,
                    ),
                    child: ChildSwitchBar(
                      label: _tab == WalletSection.recharge
                          ? 'Recargar a'
                          : 'Movimientos de',
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab == WalletSection.movements ? 1 : 0,
                      children: [
                        _buildRechargeBody(child, isLoadingChildren),
                        _buildMovements(child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(WalletSection tab) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tab = tab;
      if (tab == WalletSection.movements) _movementsOpened = true;
    });
  }

  /// Movimientos del hijo. Se crean la primera vez que se abre la sección y
  /// después se conservan: volver a "Recargar" y regresar no repite la
  /// petición. La clave cambia con el hijo (su billetera) o tras una recarga
  /// para volver a pedirlos. Sin billetera no hay nada que listar.
  Widget _buildMovements(Child? child) {
    if (!_movementsOpened) return const SizedBox.shrink();
    final walletId = child?.walletId;
    if (child == null || walletId == null) {
      return _NoWalletNotice(hasChild: child != null);
    }
    return TransactionHistoryScreen.forWallet(
      key: ValueKey('$walletId-$_movementsRevision'),
      walletId: walletId,
      childName: child.displayName,
      balance: child.balance ?? 0,
    );
  }

  Widget _buildRechargeBody(Child? child, bool isLoadingChildren) {
    if (isLoadingChildren) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary500),
      );
    }
    if (child == null || child.walletId == null) {
      return _NoWalletNotice(hasChild: child != null);
    }
    final firstName = child.firstName.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RechargeBalanceCard(
            balance: child.balance ?? 0,
            firstName: firstName,
            amountController: _amountController,
          ),
          const SizedBox(height: 22),
          Text(
            'Monto a recargar',
            style: AppText.itemTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RechargeAmountField(controller: _amountController),
          const SizedBox(height: AppSpacing.md),
          QuickAmountChips(
            controller: _amountController,
            amounts: _quickAmounts,
          ),
          const SizedBox(height: AppSpacing.xl),
          RechargeSubmitButton(
            amountController: _amountController,
            firstName: firstName,
            isLoading: _isSubmitting,
            onPressed: _proceedToRecharge,
          ),
        ],
      ),
    );
  }
}

/// Aviso cuando no hay a quién recargar: el hijo elegido no tiene billetera
/// activa (o la cuenta aún no tiene hijos). Sin formulario ni botón de recarga.
class _NoWalletNotice extends StatelessWidget {
  const _NoWalletNotice({required this.hasChild});

  final bool hasChild;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasChild
                  ? 'Este hijo aún no tiene billetera activa'
                  : 'Aún no hay hijos con billetera activa',
              textAlign: TextAlign.center,
              style: AppText.itemTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cuando el colegio la active podrás recargarla y ver sus '
              'movimientos aquí.',
              textAlign: TextAlign.center,
              style: AppText.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
