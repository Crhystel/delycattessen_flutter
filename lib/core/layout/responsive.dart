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

/// Lista desplazable que en pantallas anchas acomoda los elementos en
/// columnas (filas de altura variable, a diferencia de GridView). En
/// teléfono es una lista normal de una columna.
class ResponsiveItemList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double minItemWidth;
  final int maxColumns;
  final ScrollPhysics? physics;

  const ResponsiveItemList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spacing = 12,
    this.minItemWidth = AppLayout.minCardWidth,
    this.maxColumns = 3,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = padding.resolve(Directionality.of(context));
        final available = constraints.maxWidth - resolved.horizontal;
        final columns = AppLayout.columnsFor(
          available,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return ListView.builder(
            physics: physics,
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        final rowCount = (itemCount / columns).ceil();
        return ListView.builder(
          physics: physics,
          padding: padding,
          itemCount: rowCount,
          itemBuilder: (context, row) {
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
          },
        );
      },
    );
  }
}
