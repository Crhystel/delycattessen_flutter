import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/menu_models.dart';
import '../providers/parent_menu_controller.dart';
import '../widgets/menu_days_strip.dart';
import '../widgets/menu_dish_card.dart';
import 'dish_detail_screen.dart';

/// Menú del mes del estudiante, de solo lectura: ve los días y los platillos
/// con sus alérgenos, pero no puede agregar al carrito ni confirmar pedidos
/// (los pedidos los hace el padre). Un día bloqueado por el control parental
/// también se puede leer.
class MemberMenuScreen extends StatefulWidget {
  const MemberMenuScreen({super.key, this.menuController});

  /// Por defecto la pantalla crea (y libera) el suyo; las pruebas inyectan uno
  /// con un servicio simulado.
  final ParentMenuController? menuController;

  @override
  State<MemberMenuScreen> createState() => _MemberMenuScreenState();
}

class _MemberMenuScreenState extends State<MemberMenuScreen> {
  late final ParentMenuController _menu =
      widget.menuController ?? ParentMenuController();

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenuChanged);
    _menu.loadOwn();
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenuChanged);
    if (widget.menuController == null) _menu.dispose();
    super.dispose();
  }

  void _onMenuChanged() {
    if (mounted) setState(() {});
  }

  void _showAllergens(MenuDish dish) {
    final contains = dish.allergens.isEmpty
        ? 'Este platillo no tiene alérgenos registrados.'
        : 'Contiene: ${dish.allergens.join(', ')}.';
    AppNotificationDialog.show(
      context,
      type: NotificationType.warning,
      title: 'Alérgenos de ${dish.name}',
      message: contains,
    );
  }

  void _openDetail(MenuDish dish) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              if (!_menu.isLoading && _menu.days.isNotEmpty)
                MenuDaysStrip(
                  design: true,
                  days: _menu.days,
                  selectedDayId: _menu.selectedDay?.id,
                  onSelect: _menu.selectDay,
                ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondary500,
                  onRefresh: _menu.loadOwn,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.page,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.ink900,
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: Text('Menú del mes', style: AppText.pageTitle)),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_menu.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondary500),
          ),
        ),
      ];
    }
    final error = _menu.errorMessage;
    if (error != null) {
      return [
        _centered(
          EmptyState(
            icon: Icons.error_outline,
            title: 'No pudimos cargar el menú',
            message: error,
            actionLabel: 'Reintentar',
            onAction: _menu.loadOwn,
          ),
        ),
      ];
    }
    final day = _menu.selectedDay;
    if (day == null) {
      return [
        _centered(
          const EmptyState(
            icon: Icons.restaurant_menu,
            title: 'Aún no hay un menú publicado para la institución.',
            message:
                'Cuando la institución publique el menú mensual, aparecerá aquí.',
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(child: _buildDayHeading(day)),
      SliverResponsiveItemList(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          10,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        itemCount: day.dishes.length,
        itemBuilder: (context, index) {
          final dish = day.dishes[index];
          return MenuDishCard(
            dish: dish,
            onTap: () => _openDetail(dish),
            onShowAllergens: () => _showAllergens(dish),
          );
        },
      ),
    ];
  }

  Widget _centered(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child));

  Widget _buildDayHeading(MenuDay day) {
    final date = DateFormatter.parseIsoDate(day.date);
    final reason = day.isBlockedByParentalControl
        ? (day.blockedReason ?? 'Día bloqueado por el control parental.')
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        22,
        AppSpacing.page,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatLongCapitalized(date),
            style: AppText.sectionTitleSm,
          ),
          if (reason != null) ...[
            const SizedBox(height: 4),
            Text(reason, style: AppText.secondaryLg),
          ],
          if (day.dishes.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'No hay platillos asignados para este día',
              style: AppText.secondaryLg,
            ),
          ],
        ],
      ),
    );
  }
}
