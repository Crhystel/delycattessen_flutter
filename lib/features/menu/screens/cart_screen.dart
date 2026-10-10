import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';

class CartScreen extends StatefulWidget {
  final int studentId;
  final Map<int, int> cart;
  final List<MenuItem> menuItems;
  final Set<int> childAllergenIds;
  final String childName;
  final double? childBalance;

  const CartScreen({
    super.key,
    required this.studentId,
    required this.cart,
    required this.menuItems,
    this.childAllergenIds = const {},
    this.childName = '',
    this.childBalance,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with NotificationMixin {
  final MenuService _menuService = MenuService();
  bool _isLoading = false;

  /// Ítems del carrito resueltos contra el menú. Se ignoran ids que ya no
  /// existan en el menú para no romper la pantalla.
  List<MapEntry<MenuItem, int>> get _lines {
    final lines = <MapEntry<MenuItem, int>>[];
    for (final entry in widget.cart.entries) {
      final matches = widget.menuItems.where((i) => i.id == entry.key);
      if (matches.isNotEmpty) lines.add(MapEntry(matches.first, entry.value));
    }
    return lines;
  }

  double get _total {
    return _lines.fold(0, (sum, line) => sum + (line.key.price * line.value));
  }

  /// Ítems del carrito que contienen algún alérgeno registrado para el hijo
  /// seleccionado. Re-verificación de seguridad justo antes de pagar: el
  /// carrito pudo haberse llenado antes de un cambio de hijo o de una
  /// actualización de alergias, así que no basta con el filtrado ya hecho
  /// en MenuScreen.
  List<MenuItem> get _unsafeCartItems {
    if (widget.childAllergenIds.isEmpty) return [];
    return _lines
        .map((line) => line.key)
        .where(
          (item) =>
              item.allergens.any((a) => widget.childAllergenIds.contains(a.id)),
        )
        .toList();
  }

  Set<String> _allergenNamesFor(MenuItem item) {
    return item.allergens
        .where((a) => widget.childAllergenIds.contains(a.id))
        .map((a) => a.name)
        .toSet();
  }

  void _showBlockedDialog() {
    final unsafe = _unsafeCartItems;
    final itemsList = unsafe.map((i) => i.name).join(', ');
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este hijo';

    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'No se puede procesar el pedido',
      message:
          'El carrito contiene productos no seguros para $childLabel: '
          '$itemsList. Vuelve al menú y quítalos antes de continuar.',
    );
  }

  Future<void> _handlePayment() async {
    if (_unsafeCartItems.isNotEmpty) {
      _showBlockedDialog();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orderItems = widget.cart.entries
          .map((e) => PreOrderItem(menuItemId: e.key, quantity: e.value))
          .toList();
      final preOrder = PreOrder(studentId: widget.studentId, items: orderItems);

      await _menuService.createPreOrder(preOrder);

      if (!mounted) return;
      _showSuccessNotification();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo procesar el pedido',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessNotification() {
    showSuccessSnackBar(
      'Tu pedido ha sido registrado (-\$${_total.toStringAsFixed(2)})',
      title: '¡Pago Exitoso!',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final unsafeItems = _unsafeCartItems;
    final hasUnsafeItems = unsafeItems.isNotEmpty;
    final lines = _lines;

    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(title: const Text('Mi carrito')),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasUnsafeItems) _buildAllergenWarningBanner(unsafeItems),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final item = lines[index].key;
                      return _buildCartItemCard(
                        item,
                        lines[index].value,
                        unsafeItems.contains(item),
                      );
                    },
                  ),
                ),
                _buildBottomBar(hasUnsafeItems),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.brand500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Único aviso de alérgenos de la pantalla: lista qué producto contiene qué.
  Widget _buildAllergenWarningBanner(List<MenuItem> unsafeItems) {
    final textTheme = Theme.of(context).textTheme;
    final childLabel = widget.childName.isNotEmpty
        ? widget.childName
        : 'este hijo';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.danger500),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quita estos productos antes de pagar ($childLabel tiene alergias):',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger700,
                  ),
                ),
                const SizedBox(height: 4),
                ...unsafeItems.map(
                  (item) => Text(
                    '• ${item.name}: ${_allergenNamesFor(item).join(", ")}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(MenuItem item, int quantity, bool isUnsafe) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isUnsafe ? AppColors.dangerBg : Colors.white,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.teal50,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(Icons.fastfood, color: AppColors.teal500),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.price.toStringAsFixed(2)} c/u',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '×$quantity',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${(item.price * quantity).toStringAsFixed(2)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool hasUnsafeItems) {
    final textTheme = Theme.of(context).textTheme;
    final total = _total;
    final insufficient =
        widget.childBalance != null && widget.childBalance! < total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.childBalance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.childName.isNotEmpty
                        ? 'Saldo de ${widget.childName}'
                        : 'Saldo disponible',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '\$${widget.childBalance!.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: insufficient
                          ? AppColors.danger500
                          : AppColors.success700,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (insufficient)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'El saldo no alcanza. Recarga en la pestaña Billetera.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.danger500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (hasUnsafeItems)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink900.withValues(alpha: 0.2),
                  foregroundColor: AppColors.ink900,
                ),
                onPressed: _isLoading ? null : _handlePayment,
                child: const Text('Revisa tu carrito'),
              ),
            )
          else
            PrimaryButton(
              label: 'Pagar \$${total.toStringAsFixed(2)}',
              icon: Icons.check_circle_outline,
              isLoading: false,
              onPressed: _isLoading ? null : _handlePayment,
            ),
        ],
      ),
    );
  }
}
