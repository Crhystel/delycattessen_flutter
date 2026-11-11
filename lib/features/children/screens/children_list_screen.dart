import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/tab_header.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../../menu/models/menu_models.dart';
import '../../menu/services/menu_service.dart';
import '../../menu/utils/upcoming_menu_labels.dart';
import '../../menu/widgets/combo_banner.dart';
import '../../menu/widgets/upcoming_menu_card.dart';
import '../providers/children_provider.dart';
import '../widgets/child_summary_card.dart';
import '../widgets/low_balance_alert_card.dart';
import 'child_detail_screen.dart';

/// Pestaña Inicio del padre: quién necesita recarga, todos sus hijos y lo que
/// viene en el menú. Las acciones que cambian de pestaña las resuelve el
/// ParentShell (callbacks).
class ChildrenListScreen extends StatefulWidget {
  /// Burbuja de perfil que pone el ParentShell en la cabecera.
  final Widget? profileAction;

  /// Nombre para el saludo.
  final String userName;

  /// Elige al hijo y lleva a la pestaña Menú.
  final void Function(int childId)? onOrderForChild;

  /// Abre la pestaña Menú con un día preseleccionado.
  final void Function(int childId, DateTime date)? onOpenMenuDay;

  /// Lleva a Billetera con el hijo elegido para recargarle.
  final void Function(int childId)? onRechargeChild;

  /// Abre el catálogo de productos (sección Productos).
  final VoidCallback? onOpenProducts;

  final MenuService? menuService;

  const ChildrenListScreen({
    super.key,
    this.profileAction,
    this.userName = '',
    this.onOrderForChild,
    this.onOpenMenuDay,
    this.onRechargeChild,
    this.onOpenProducts,
    this.menuService,
  });

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  late final MenuService _menuService = widget.menuService ?? MenuService();

  MenuDay? _firstAvailableMenuDay;
  Combo? _combo;
  bool _isLoadingMenu = false;
  int? _loadedStudentId;

  /// Identifica la carga vigente del menú: una respuesta de una carga anterior
  /// (otro hijo, o un pull-to-refresh encima) se descarta.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChildrenProvider>();
    Future.microtask(() async {
      await provider.ensureLoaded();
      _syncMenuPreview();
    });
  }

  void _syncMenuPreview() {
    if (!mounted) return;
    final child = context.read<ChildrenProvider>().selectedChild;
    if (child != null && child.id != _loadedStudentId) {
      _loadMenuPreview(child.id);
    }
  }

  /// Primer día con platillos y primer combo vigente del hijo elegido. Es una
  /// vista informativa: si falla, simplemente no se muestra. Las dos peticiones
  /// salen a la vez y cada una atiende su propio error.
  Future<void> _loadMenuPreview(int studentId) async {
    _loadedStudentId = studentId;
    final token = ++_loadToken;
    setState(() => _isLoadingMenu = true);
    final dayFuture = _fetchFirstMenuDay(studentId);
    final comboFuture = _fetchFirstCombo(studentId);
    final day = await dayFuture;
    final combo = await comboFuture;
    if (!mounted || token != _loadToken) return;
    setState(() {
      _firstAvailableMenuDay = day;
      _combo = combo;
      _isLoadingMenu = false;
    });
  }

  Future<MenuDay?> _fetchFirstMenuDay(int studentId) async {
    try {
      final days = await _menuService.getStudentMonthlyMenu(studentId);
      return days.where((d) => d.dishes.isNotEmpty).firstOrNull;
    } catch (_) {
      // Sin menú publicado o sin conexión: la tarjeta no se muestra.
      return null;
    }
  }

  Future<Combo?> _fetchFirstCombo(int studentId) async {
    try {
      final offers = await _menuService.getActiveOffers(studentId: studentId);
      return offers.combos.firstOrNull;
    } catch (_) {
      // Las ofertas son secundarias: sin ellas no hay banner.
      return null;
    }
  }

  /// "Lunes, 9 de noviembre".
  String get _todayLabel {
    final now = DateTime.now();
    final weekday = DateFormatter.weekdayName(now);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}, '
        '${now.day} de ${DateFormatter.monthName(now)}';
  }

  Future<void> _openChildDetail(Child child) async {
    final provider = context.read<ChildrenProvider>();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)));
    provider.refresh();
  }

  Future<void> _addChild() async {
    final provider = context.read<ChildrenProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
    );
    provider.refresh();
  }

  void _openMenuDay(int childId, DateTime date) {
    final openDay = widget.onOpenMenuDay;
    if (openDay != null) {
      openDay(childId, date);
    } else {
      widget.onOrderForChild?.call(childId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildrenProvider>();
    final children = provider.children;
    final target = provider.selectedChild;

    // Si cambió el hijo seleccionado, se actualiza la vista del menú.
    if (target != null && target.id != _loadedStudentId && !_isLoadingMenu) {
      Future.microtask(_syncMenuPreview);
    }

    return AppScaffold(
      backgroundColor: AppColors.ink50,
      bubbleCorner: BubbleCorner.topRight,
      bubblesDesign: true,
      safeAreaTop: false,
      body: RefreshIndicator(
        color: AppColors.secondary500,
        edgeOffset: MediaQuery.viewPaddingOf(context).top,
        onRefresh: () async {
          await provider.refresh();
          if (target != null) await _loadMenuPreview(target.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // The header brings its own top and side margins (TabHeader); the
          // body below gets the side margins from the Padding.
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabHeader(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _todayLabel,
                      style: AppText.secondary.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¡Hola, ${widget.userName.isNotEmpty ? widget.userName : "Usuario"}!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.greeting,
                    ),
                  ],
                ),
                trailing: widget.profileAction,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildBody(provider, children),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(ChildrenProvider provider, List<Child> children) {
    if (provider.isLoading && !provider.hasLoadedOnce) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondary500),
          ),
        ),
      ];
    }
    if (provider.errorMessage != null) {
      return [
        const SizedBox(height: AppSpacing.xl),
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar tus hijos',
          message: provider.errorMessage,
          actionLabel: 'Reintentar',
          onAction: provider.refresh,
        ),
      ];
    }

    final lowBalance = children.where((c) => c.hasLowBalance).toList();
    final target = provider.selectedChild;
    final day = _firstAvailableMenuDay;
    final dish = day?.dishes.firstOrNull;
    final dayDate = day == null ? null : DateFormatter.parseIsoDate(day.date);

    return [
      for (var i = 0; i < lowBalance.length; i++) ...[
        SizedBox(height: i == 0 ? 26 : AppSpacing.md),
        LowBalanceAlertCard(
          child: lowBalance[i],
          onRecharge: () => widget.onRechargeChild?.call(lowBalance[i].id),
        ),
      ],
      const SizedBox(height: 28),
      _SectionHeader(
        title: 'Tus hijos',
        trailing: Text(
          children.length == 1
              ? '1 registrado'
              : '${children.length} registrados',
          style: AppText.secondary.copyWith(fontSize: 14),
        ),
      ),
      const SizedBox(height: 10),
      _ChildrenGrid(
        children: [
          for (final child in children)
            ChildSummaryCard(
              child: child,
              onTap: () => _openChildDetail(child),
            ),
          _AddChildCard(onTap: _addChild),
        ],
      ),
      const SizedBox(height: 28),
      _SectionHeader(
        // Sin platillos publicados el título queda neutro ("Menú").
        title: dayDate == null
            ? 'Menú'
            : UpcomingMenuLabels.sectionTitle(dayDate, DateTime.now()),
        trailing: _SectionLink(
          label: 'Ver menú',
          onTap: target == null
              ? null
              : () => widget.onOrderForChild?.call(target.id),
        ),
      ),
      const SizedBox(height: 10),
      if (target != null && dish != null && dayDate != null)
        UpcomingMenuCard(
          dish: dish,
          date: dayDate,
          onOrder: () => _openMenuDay(target.id, dayDate),
        )
      else
        _PreviewPlaceholder(
          icon: Icons.restaurant_menu,
          message: _isLoadingMenu
              ? 'Cargando el menú…'
              : 'Aún no hay platillos publicados para los próximos días.',
          onTap: target == null
              ? null
              : () => widget.onOrderForChild?.call(target.id),
        ),
      const SizedBox(height: 28),
      _SectionHeader(
        title: 'Productos',
        trailing: _SectionLink(
          label: 'Ver productos',
          onTap: widget.onOpenProducts,
        ),
      ),
      const SizedBox(height: 10),
      if (_combo != null)
        ComboBanner(combo: _combo!, onTap: () => widget.onOpenProducts?.call())
      else
        _PreviewPlaceholder(
          icon: Icons.local_offer_outlined,
          message: _isLoadingMenu
              ? 'Cargando los productos…'
              : 'Mira los productos y combos disponibles.',
          onTap: widget.onOpenProducts,
        ),
    ];
  }
}

/// Grilla de tarjetas con columnas automáticas (≈136 px mínimo cada una): 2 en
/// teléfono, más en tablet. Las filas toman la altura de su tarjeta más alta.
class _ChildrenGrid extends StatelessWidget {
  const _ChildrenGrid({required this.children});

  final List<Widget> children;

  static const double _minCardWidth = 136;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gap) / (_minCardWidth + _gap))
            .floor()
            .clamp(1, 4);
        final rows = (children.length / columns).ceil();
        return Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: r * columns + c < children.length
                            ? children[r * columns + c]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Tarjeta "Añadir hijo/a": borde discontinuo morado, como en el diseño.
class _AddChildCard extends StatelessWidget {
  const _AddChildCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Añadir hijo o hija',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: DashedBorder(
          radius: AppRadius.card,
          child: Container(
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary50,
                  child: Icon(
                    Icons.add,
                    size: 22,
                    color: AppColors.secondary500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Añadir hijo/a',
                  textAlign: TextAlign.center,
                  style: AppText.link.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de respaldo de Inicio cuando una sección (Menú o Productos) aún no
/// tiene nada que mostrar: sigue siendo un acceso a esa pestaña.
class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.cardAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondary50,
                child: Icon(icon, color: AppColors.secondary500),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: AppText.secondaryLg)),
              const Icon(Icons.chevron_right, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de una sección de Inicio con un texto o enlace a la derecha, alineados
/// por la línea base. El título cede espacio (puntos suspensivos) antes de
/// desbordar la fila.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sectionTitle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}

/// Enlace de texto morado de una sección ("Ver menú", "Ver productos"). Sin
/// [onTap] queda deshabilitado en gris.
class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fieldAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: onTap == null
                ? AppText.link.copyWith(color: AppColors.chevron)
                : AppText.link,
          ),
        ),
      ),
    );
  }
}
