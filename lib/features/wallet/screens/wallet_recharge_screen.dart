import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/segmented_switch.dart';
import 'pin_entry_screen.dart';
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

/// Secciones de la pestaña Billetera del padre.
enum _WalletTab { recharge, movements }

class WalletRechargeScreen extends StatefulWidget {
  /// Opcional: si se pasa, la pantalla usa esta lista fija en vez de leer
  /// del ChildrenProvider (útil si algún día hace falta un flujo con una
  /// selección ya acotada desde afuera).
  final List<ChildOption>? children;
  final int? initialWalletId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  /// Burbuja de perfil a la derecha del título (la pone el ParentShell).
  final Widget? profileAction;

  const WalletRechargeScreen({
    super.key,
    this.children,
    this.initialWalletId,
    this.embedded = false,
    this.profileAction,
  });

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen>
    with NotificationMixin {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  int? _selectedWalletId;
  ChildrenProvider? _childrenProvider;
  bool _isSubmitting = false;
  _WalletTab _tab = _WalletTab.recharge;

  /// Movimientos se crea al abrirlo por primera vez y luego se conserva.
  bool _movementsOpened = false;

  static const List<double> _quickAmounts = [5.00, 10.00, 15.00, 20.00];

  @override
  void initState() {
    super.initState();
    _selectedWalletId = widget.initialWalletId;
    if (widget.children == null) {
      _childrenProvider = context.read<ChildrenProvider>();
      if (widget.embedded && _selectedWalletId == null) {
        _selectedWalletId = _childrenProvider!.selectedChild?.walletId;
      }
      if (widget.embedded) {
        _childrenProvider!.addListener(_onSelectedChildChanged);
      }
      Future.microtask(() => _childrenProvider!.ensureLoaded());
    }
  }

  /// La billetera sigue al hijo seleccionado global.
  void _onSelectedChildChanged() {
    final walletId = _childrenProvider?.selectedChild?.walletId;
    if (!mounted || walletId == null || walletId == _selectedWalletId) return;
    setState(() => _selectedWalletId = walletId);
  }

  @override
  void dispose() {
    _childrenProvider?.removeListener(_onSelectedChildChanged);
    _amountController.dispose();
    super.dispose();
  }

  /// Hijos con billetera activa, como ChildOption. Si la pantalla recibió
  /// una lista fija por constructor la usa tal cual; si no, la deriva del
  /// ChildrenProvider compartido (sin volver a pedir getChildren()).
  List<ChildOption> _childrenOptions(
    BuildContext context, {
    bool listen = true,
  }) {
    if (widget.children != null) return widget.children!;
    final children =
        (listen
                ? context.watch<ChildrenProvider>()
                : context.read<ChildrenProvider>())
            .children;
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
    final selectedChild = _resolveSelectedChild(
      _childrenOptions(context, listen: false),
    );
    final amount = _enteredAmount;
    if (amount == null || amount <= 0) {
      showWarningSnackBar(
        'Ingresa un monto válido para recargar.',
        title: 'Monto inválido',
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
          walletId: selectedChild.walletId,
          childName: selectedChild.name,
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

  /// Cierre común a todas las pasarelas: aviso, saldos al día y volver.
  Future<void> _finishRecharge(double amount) async {
    showSuccessSnackBar(
      'Tu recarga de \$${amount.toStringAsFixed(2)} se acreditó correctamente.',
      title: '¡Recarga exitosa!',
    );
    if (widget.children == null) {
      await context.read<ChildrenProvider>().refresh();
    }
    if (!mounted) return;
    if (widget.embedded) {
      setState(_amountController.clear); // pestaña del shell: no se cierra
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
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
    final embedded = widget.embedded;
    final rechargeBody = _buildRechargeBody(
      children,
      selectedChild,
      isLoadingChildren,
    );

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          // Las burbujas no cambian: se pintan una sola vez en su propia capa.
          RepaintBoundary(
            child: FloatingBubbles(
              corner: BubbleCorner.topRight,
              design: embedded,
            ),
          ),
          ResponsiveCenter(
            child: SafeArea(
              // Embebida, el margen superior lo da la cabecera con el inset
              // real del dispositivo (la app dibuja de borde a borde).
              top: !embedded,
              child: Column(
                children: [
                  _buildHeader(context),
                  if (embedded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.lg,
                        AppSpacing.page,
                        0,
                      ),
                      child: SegmentedSwitch<_WalletTab>(
                        palette: SegmentedSwitchPalette.blue,
                        options: const [
                          (_WalletTab.recharge, 'Recargar'),
                          (_WalletTab.movements, 'Movimientos'),
                        ],
                        selected: _tab,
                        onChanged: _onTabChanged,
                      ),
                    ),
                  if (embedded && widget.children == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.lg,
                        AppSpacing.page,
                        14,
                      ),
                      child: ChildSwitchBar(
                        label: _tab == _WalletTab.recharge
                            ? 'Recargar a'
                            : 'Movimientos de',
                      ),
                    ),
                  Expanded(
                    child: embedded
                        ? IndexedStack(
                            index: _tab == _WalletTab.movements ? 1 : 0,
                            children: [
                              rechargeBody,
                              _buildMovements(selectedChild),
                            ],
                          )
                        : rechargeBody,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(_WalletTab tab) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tab = tab;
      if (tab == _WalletTab.movements) _movementsOpened = true;
    });
  }

  /// Movimientos del hijo. Se crean la primera vez que se abre la sección y
  /// después se conservan: volver a "Recargar" y regresar no repite la
  /// petición. La clave cambia con el hijo o el saldo para volver a pedirlos.
  Widget _buildMovements(ChildOption? selectedChild) {
    if (!_movementsOpened || selectedChild == null) {
      return const SizedBox.shrink();
    }
    return TransactionHistoryScreen.forWallet(
      key: ValueKey(
        '${selectedChild.walletId}-${selectedChild.currentBalance}',
      ),
      walletId: selectedChild.walletId,
      childName: selectedChild.name,
      embedded: true,
      balance: selectedChild.currentBalance,
    );
  }

  Widget _buildRechargeBody(
    List<ChildOption> children,
    ChildOption? selectedChild,
    bool isLoadingChildren,
  ) {
    final design = widget.embedded;
    final balance = selectedChild?.currentBalance ?? 0.0;
    final firstName = selectedChild?.name.split(' ').first;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        design ? 0 : 4,
        AppSpacing.page,
        design ? AppSpacing.xl : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) ...[
            Text(
              'Selecciona a quién recargar',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            _buildChildSelector(children, selectedChild, isLoadingChildren),
            const SizedBox(height: 20),
          ] else if (isLoadingChildren)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.secondary500),
              ),
            ),
          RechargeBalanceCard(
            balance: balance,
            firstName: firstName ?? 'Usuario',
            amountController: _amountController,
            design: design,
          ),
          SizedBox(height: design ? 22 : 24),
          Text(
            'Monto a recargar',
            style: design
                ? AppText.itemTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )
                : textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: design ? 8 : 10),
          RechargeAmountField(controller: _amountController, design: design),
          SizedBox(height: design ? 12 : 14),
          QuickAmountChips(
            controller: _amountController,
            amounts: _quickAmounts,
            design: design,
          ),
          SizedBox(height: design ? 24 : 28),
          RechargeSubmitButton(
            amountController: _amountController,
            firstName: firstName,
            isLoading: _isSubmitting,
            onPressed: _proceedToRecharge,
            design: design,
          ),
          SizedBox(height: design ? 0 : 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.embedded) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppLayout.pageTopPadding(context),
          AppSpacing.page,
          0,
        ),
        child: Row(
          children: [
            Expanded(child: Text('Billetera', style: AppText.tabTitle)),
            if (widget.profileAction != null) widget.profileAction!,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 12),
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
          Expanded(
            child: Text(
              'Billetera',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
          ),
          if (widget.profileAction != null) widget.profileAction!,
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
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: children.map((child) {
        final isSelected = child.walletId == selectedChild?.walletId;
        return GestureDetector(
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
                    : AppColors.lineStrong,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ChildAvatarChip(imageUrl: child.profilePictureUrl, radius: 18),
                const SizedBox(height: 6),
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.ink900,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
