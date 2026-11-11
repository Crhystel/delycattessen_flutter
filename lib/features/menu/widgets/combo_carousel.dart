import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';
import 'catalog_stock_badges.dart';

/// "Combos de hoy" de la vista del padre: tarjetas con foto que avanzan solas
/// cada pocos segundos (o con un deslizamiento), con el contador "1 de 3" y
/// puntos para saltar a uno. Cada tarjeta deja asomar el borde de la siguiente.
/// Tocar una tarjeta abre el detalle del combo.
class ComboCarousel extends StatefulWidget {
  const ComboCarousel({
    super.key,
    required this.combos,
    this.onComboTap,
    this.autoAdvance = const Duration(milliseconds: 3500),
  });

  final List<Combo> combos;
  final ValueChanged<Combo>? onComboTap;

  /// Tiempo entre avances automáticos.
  final Duration autoAdvance;

  @override
  State<ComboCarousel> createState() => _ComboCarouselState();
}

class _ComboCarouselState extends State<ComboCarousel> {
  static const double _gap = 12;
  static const double _viewportFraction = 0.86;
  static const double _maxCardWidth = 440;
  static const double _swipeVelocity = 200;

  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  int _index = 0;
  double _cardWidth = 0;

  /// False while the tab hosting the carousel is hidden (an IndexedStack keeps
  /// it alive): no timer runs for a page nobody sees.
  bool _visible = true;

  int get _count => widget.combos.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible && _timer != null) return;
    _visible = visible;
    _restartTimer();
  }

  @override
  void didUpdateWidget(ComboCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _count) _index = 0;
    // The parent rebuilds often (every keystroke in the search, etc.): only
    // touch the timer when what it depends on changed.
    if (oldWidget.autoAdvance != widget.autoAdvance ||
        !_sameCombos(oldWidget.combos, widget.combos)) {
      _restartTimer();
    }
  }

  static bool _sameCombos(List<Combo> a, List<Combo> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_count < 2 || !_visible) return;
    _timer = Timer.periodic(widget.autoAdvance, (_) => _goTo(_index + 1));
  }

  void _goTo(int index) {
    if (!mounted || _count == 0) return;
    final target = (index + _count) % _count;
    setState(() => _index = target);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        target * (_cardWidth + _gap),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocity) {
      _goTo(_index + 1);
    } else if (velocity >= _swipeVelocity) {
      _goTo(_index - 1);
    }
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Combos de hoy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sectionTitleSm,
              ),
            ),
            if (_count > 1)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  '${_index + 1} de $_count',
                  style: AppText.secondaryLg,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            _cardWidth = math.min(
              constraints.maxWidth * _viewportFraction,
              _maxCardWidth,
            );
            // Always the same share of the width (a single combo too), as in
            // the design.
            final width = _cardWidth;
            return GestureDetector(
              onHorizontalDragStart: (_) => _timer?.cancel(),
              onHorizontalDragEnd: _onDragEnd,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _count; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        SizedBox(
                          width: width,
                          child: _ComboSlide(
                            combo: widget.combos[i],
                            onTap: widget.onComboTap == null
                                ? null
                                : () => widget.onComboTap!(widget.combos[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_count > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                Semantics(
                  button: true,
                  label: 'Ver combo ${i + 1} de $_count',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _goTo(i);
                      _restartTimer();
                    },
                    child: SizedBox(
                      width: 32,
                      height: 24,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: i == _index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.secondary500
                                : AppColors.brandBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Una tarjeta del carrusel: foto con "COMBO" y la vigencia, nombre, los
/// platillos que incluye y el precio con lo que se ahorra.
class _ComboSlide extends StatelessWidget {
  const _ComboSlide({required this.combo, required this.onTap});

  final Combo combo;
  final VoidCallback? onTap;

  static const double _imageHeight = 180;

  String get _until =>
      'Hasta el ${combo.endDate.day} ${DateFormatter.shortMonthName(combo.endDate)}';

  String get _dishes => combo.items
      .map((i) => i.quantity > 1 ? '${i.name} ×${i.quantity}' : i.name)
      .join(' + ');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Combo ${combo.name}. $_until',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(context),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _Pill(
                          label: 'COMBO',
                          background: AppColors.brand500,
                          foreground: AppColors.ink900,
                          bold: true,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _Pill(
                          label: _until,
                          background: Colors.white,
                          foreground: AppColors.brand700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        combo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle,
                      ),
                      Text(
                        _dishes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.secondaryLg,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '\$${combo.price.toStringAsFixed(2)}',
                            style: AppText.price.copyWith(
                              fontSize: 24,
                              color: AppColors.brand700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (combo.hasSavings) ...[
                            Text(
                              '\$${combo.regularPrice.toStringAsFixed(2)}',
                              style: AppText.secondary.copyWith(
                                fontSize: 14,
                                color: AppColors.placeholder,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            _Pill(
                              label:
                                  'Ahorras \$${combo.savings.toStringAsFixed(2)}',
                              background: AppColors.successBg,
                              foreground: AppColors.success700,
                              fontSize: 12.5,
                              weight: FontWeight.w700,
                            ),
                          ],
                          ?CatalogStockBadges.low(
                            combo.availableQuantity,
                          )?.asPill(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final url = combo.imageUrl;
    const placeholder = ColoredBox(
      color: AppColors.brand50,
      child: Icon(Icons.local_offer, color: AppColors.brand500, size: 40),
    );
    if (url == null) return placeholder;
    return LayoutBuilder(
      builder: (context, constraints) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: AppImageCacheHelper.cacheSize(
          context,
          constraints.maxWidth,
        ),
        placeholder: (_, _) => const ColoredBox(color: AppColors.brand50),
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.bold = false,
    this.fontSize = 12,
    this.weight,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool bold;
  final double fontSize;

  /// Peso de la letra; por defecto 800 si [bold] y 600 si no.
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight ?? (bold ? FontWeight.w800 : FontWeight.w600),
          letterSpacing: bold ? 0.5 : 0,
          color: foreground,
        ),
      ),
    );
  }
}
