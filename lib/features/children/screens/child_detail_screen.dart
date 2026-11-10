import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../auth/models/auth_models.dart';
import '../../users/models/allergy_models.dart';
import '../../users/screens/allergy_management_screen.dart';
import '../../users/services/allergy_owner.dart';
import '../../wallet/screens/transaction_history_screen.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../providers/child_movements_controller.dart';
import '../providers/child_settings_controller.dart';
import '../utils/allergy_summary.dart';
import '../utils/parental_control_summary.dart';
import '../widgets/child_balance_card.dart';
import '../widgets/child_detail_header.dart';
import '../widgets/child_info_row.dart';
import '../widgets/child_recent_movements.dart';
import 'edit_child_screen.dart';
import 'parental_control_screen.dart';

/// Ficha de un hijo: saldo con "Recargar", su día (límite diario y alergias)
/// y sus últimos movimientos. El lápiz abre sus datos.
///
/// Pops with `true` when something changed so the list refreshes.
class ChildDetailScreen extends StatefulWidget {
  final Child child;

  /// Resúmenes de alergias y control parental; se crean solos si no se dan
  /// (se inyectan en pruebas).
  final ChildSettingsController? settings;

  /// Últimos movimientos de la billetera; se crea solo si no se da.
  final ChildMovementsController? movements;

  const ChildDetailScreen({
    super.key,
    required this.child,
    this.settings,
    this.movements,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with NotificationMixin {
  late Child _currentChild;
  // Tells the list to refresh when the data changed.
  bool _hasChanges = false;
  late final ChildSettingsController _settings;
  late final bool _ownsSettings;
  ChildMovementsController? _movements; // null = el hijo no tiene billetera
  late final bool _ownsMovements;

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _ownsSettings = widget.settings == null;
    _settings =
        widget.settings ?? ChildSettingsController(studentId: _currentChild.id);
    _settings.load();

    final walletId = _currentChild.walletId;
    _ownsMovements = widget.movements == null;
    _movements =
        widget.movements ??
        (walletId == null
            ? null
            : ChildMovementsController(walletId: walletId));
    _movements?.load();
  }

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    if (_ownsMovements) _movements?.dispose();
    super.dispose();
  }

  void _goToHistory() {
    final walletId = _currentChild.walletId;
    if (walletId == null) {
      showWarningSnackBar('Este hijo aún no tiene billetera activa.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen.forWallet(
          walletId: walletId,
          childName: _currentChild.displayName,
        ),
      ),
    );
  }

  Future<void> _goToWallet() async {
    if (_currentChild.walletId == null) {
      showWarningSnackBar('Este hijo aún no tiene billetera activa.');
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WalletRechargeScreen(initialWalletId: _currentChild.walletId!),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _goToParentalControl() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentalControlScreen(
          studentId: _currentChild.id,
          studentName: _currentChild.displayName,
        ),
      ),
    );
    if (!mounted) return;
    _settings.loadParentalControl(); // refresca el resumen con lo guardado
  }

  Future<void> _goToAllergies() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllergyManagementScreen(
          owner: StudentAllergyOwner(_currentChild.id),
          personName: _currentChild.displayName,
          parentStyle: true,
        ),
      ),
    );
    if (!mounted) return;
    _settings.loadAllergies();
    if (result == true) {
      Navigator.of(context).pop(true); // avisa a Inicio que refresque
    }
  }

  Future<void> _editData() async {
    final updated = await Navigator.of(context).push<Child>(
      MaterialPageRoute(builder: (_) => EditChildScreen(child: _currentChild)),
    );
    if (!mounted) return;
    // Datos del hijo también edita control parental y alergias.
    _settings.load();
    if (updated == null) return;
    setState(() {
      _currentChild = updated;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = _currentChild;
    final movements = _movements;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        backgroundColor: AppColors.ink50,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChildDetailHeader(
                child: child,
                onBack: () => Navigator.of(context).pop(_hasChanges),
                onEdit: _editData,
              ),
              // El contenido sube sobre la franja inferior de la cabecera: la
              // tarjeta de saldo queda a medias sobre el morado. Transform no
              // cambia el layout, por eso abajo se suma esa misma altura.
              Transform.translate(
                offset: const Offset(0, -ChildDetailHeader.balanceOverlap),
                child: ResponsiveCenter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      ChildDetailHeader.balanceOverlap +
                          AppSpacing.xl +
                          MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChildBalanceCard(
                          balance: child.balance ?? 0,
                          onRecharge: _goToWallet,
                        ),
                        const SizedBox(height: 22),
                        Text('Su día', style: AppText.sectionTitleXs),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDayCard(),
                        if (movements != null) ...[
                          const SizedBox(height: 22),
                          ChildRecentMovements(
                            controller: movements,
                            onSeeAll: _goToHistory,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard() {
    return AppCard(
      design: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            final allergies = _settings.allergies;
            return Column(
              children: [
                ChildInfoRow(
                  icon: Icons.shield_outlined,
                  title: 'Límite diario',
                  onTap: _goToParentalControl,
                  child: Text(
                    ParentalControlSummary.detailed(_settings.parentalControl),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondaryLg,
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ChildInfoRow(
                  icon: Icons.warning_amber_outlined,
                  iconBackground: AppColors.dangerBg,
                  iconColor: AppColors.danger700,
                  title: 'Alergias',
                  onTap: _goToAllergies,
                  child: _buildAllergiesContent(allergies),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllergiesContent(List<Allergen>? allergies) {
    if (allergies == null) {
      return Text(AllergySummary.placeholder, style: AppText.secondaryLg);
    }
    if (allergies.isEmpty) {
      return Text(AllergySummary.none, style: AppText.secondaryLg);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final a in allergies) AllergyPill(name: a.name)],
        ),
        const SizedBox(height: 6),
        Text(
          'Te avisamos en el menú si un plato las contiene',
          style: AppText.caption,
        ),
      ],
    );
  }
}
