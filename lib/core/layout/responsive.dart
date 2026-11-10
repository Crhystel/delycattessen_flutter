import 'package:flutter/material.dart';

/// Anchos de referencia para adaptar la app a tablets. El diseño del Figma
/// es de teléfono (402 de ancho); en pantallas más grandes el contenido se
/// centra con un ancho máximo y las listas pasan a varias columnas.
class AppLayout {
  /// Desde este lado más corto se considera tablet (Material: 600 dp).
  static const double tabletBreakpoint = 600;

  /// Formularios (login, registro, PIN, tarjeta).
  static const double formMaxWidth = 520;

  /// Pantallas de contenido (inicio, detalle, historial, carrito).
  static const double pageMaxWidth = 720;

  /// Catálogos y listas en cuadrícula.
  static const double wideMaxWidth = 1100;

  /// Ancho mínimo de una tarjeta de producto/platillo en la cuadrícula.
  static const double minCardWidth = 340;

  /// Distancia desde el borde superior de la pantalla hasta el título de una
  /// cabecera del padre: zona de la barra de estado o de la cámara (que la app
  /// dibuja de borde a borde) más un margen fijo. Así el título queda a la
  /// misma distancia de las burbujas en cualquier dispositivo.
  static double pageTopPadding(BuildContext context, {double extra = 16}) {
    final inset = MediaQuery.viewPaddingOf(context).top;
    return inset + extra;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;

  /// Columnas que caben en [width] sin que cada una baje de [minItemWidth].
  static int columnsFor(
    double width, {
    double minItemWidth = minCardWidth,
    int maxColumns = 3,
  }) {
    final columns = (width / minItemWidth).floor();
    return columns.clamp(1, maxColumns);
  }
}

/// Centra [child] horizontalmente y limita su ancho a [maxWidth]. En teléfono
/// no cambia nada, porque la pantalla ya es más angosta que el máximo.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.pageMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ancho fijo (no "suelto") para que el contenido se vea igual que
        // antes en teléfono; la altura se respeta si el padre la limita.
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// Lista (sliver) que en pantallas anchas acomoda los elementos en columnas
/// (filas de altura variable, a diferencia de GridView). En teléfono es una
/// lista normal de una columna. Va dentro de un `CustomScrollView`, junto a la
/// cabecera que se encoge y a las ofertas.
class SliverResponsiveItemList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double minItemWidth;
  final int maxColumns;

  const SliverResponsiveItemList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spacing = 12,
    this.minItemWidth = AppLayout.minCardWidth,
    this.maxColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final resolved = padding.resolve(Directionality.of(context));
        final available = constraints.crossAxisExtent - resolved.horizontal;
        final columns = AppLayout.columnsFor(
          available,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
        );
        return SliverPadding(
          padding: padding,
          sliver: columns == 1
              ? SliverList.builder(
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                )
              : SliverList.builder(
                  itemCount: (itemCount / columns).ceil(),
                  itemBuilder: (context, row) =>
                      _buildRow(context, row, columns),
                ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, int row, int columns) {
    final start = row * columns;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var col = 0; col < columns; col++) ...[
            if (col > 0) SizedBox(width: spacing),
            Expanded(
              child: start + col < itemCount
                  ? itemBuilder(context, start + col)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
