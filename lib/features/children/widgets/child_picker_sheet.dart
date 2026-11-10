import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../auth/models/auth_models.dart';
import '../providers/children_provider.dart';
import 'child_avatar.dart';

/// Hoja "¿Para quién?": lista de hijos con buscador, saldo y la marca de saldo
/// bajo. Elige al hijo seleccionado global. Con [onAddChild] muestra además el
/// botón "Añadir hijo/a". Usada por toda pantalla donde el padre cambia de hijo.
class ChildPickerSheet {
  ChildPickerSheet._();

  static Future<void> show(
    BuildContext context,
    ChildrenProvider provider, {
    String title = '¿Para quién?',
    VoidCallback? onAddChild,
  }) {
    final count = provider.children.length;
    return AppBottomSheet.show<void>(
      context,
      title: title,
      subtitle: count == 1 ? '1 hijo registrado' : '$count hijos registrados',
      isScrollControlled: true,
      design: true,
      showCloseButton: true,
      builder: (sheetContext) => _ChildPickerContent(
        provider: provider,
        onAddChild: onAddChild == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                onAddChild();
              },
        onSelected: () => Navigator.pop(sheetContext),
      ),
    );
  }
}

class _ChildPickerContent extends StatefulWidget {
  const _ChildPickerContent({
    required this.provider,
    required this.onSelected,
    this.onAddChild,
  });

  final ChildrenProvider provider;
  final VoidCallback onSelected;
  final VoidCallback? onAddChild;

  @override
  State<_ChildPickerContent> createState() => _ChildPickerContentState();
}

class _ChildPickerContentState extends State<_ChildPickerContent> {
  /// Parte de la pantalla que puede ocupar el contenido de la hoja; el resto
  /// queda para el asa y la cabecera, así la hoja nunca llega arriba del todo.
  static const double _maxHeightFactor = 0.6;

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final needle = _query.trim().toLowerCase();
    final children = provider.children
        .where((c) => c.displayName.toLowerCase().contains(needle))
        .toList();
    final selectedId = provider.selectedChild?.id;

    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxHeight = (media.size.height - keyboard) * _maxHeightFactor;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchField(onChanged: (value) => setState(() => _query = value)),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final child in children)
                    _ChildOption(
                      child: child,
                      selected: child.id == selectedId,
                      onTap: () {
                        provider.select(child.id);
                        widget.onSelected();
                      },
                    ),
                  if (children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Text(
                        'No encontramos a nadie con ese nombre.',
                        textAlign: TextAlign.center,
                        style: AppText.secondaryLg,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.onAddChild != null) _Footer(onAdd: widget.onAddChild!),
          ],
        ),
      ),
    );
  }
}

/// Buscador en forma de pastilla (46 de alto). No usa el `InputDecoration`
/// global: el diseño lo pide más liviano.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.ink50,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Buscar hijo',
              child: TextField(
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppText.rowTitle.copyWith(fontSize: 15),
                decoration: InputDecoration.collapsed(
                  hintText: 'Buscar por nombre',
                  hintStyle: AppText.rowTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.placeholder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie fijo con borde superior `divider` (que llega a los bordes de la hoja) y
/// el botón "Añadir hijo/a" de borde punteado.
class _Footer extends StatelessWidget {
  const _Footer({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // La hoja deja un margen lateral de `AppSpacing.page`; el borde del pie
        // lo ignora para ir de lado a lado, como en el diseño.
        SizedBox(
          height: 1,
          child: LayoutBuilder(
            builder: (context, constraints) => OverflowBox(
              minWidth: constraints.maxWidth + AppSpacing.page * 2,
              maxWidth: constraints.maxWidth + AppSpacing.page * 2,
              child: const Divider(height: 1, color: AppColors.divider),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DashedBorder(
          radius: 26,
          strokeWidth: 1.5,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.secondary500,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Añadir hijo/a',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.rowTitle.copyWith(
                          fontSize: 15,
                          color: AppColors.secondary500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildOption extends StatelessWidget {
  const _ChildOption({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Child child;
  final bool selected;
  final VoidCallback onTap;

  /// Ancho fijo de la columna del saldo: el monto y "Saldo bajo" quedan siempre
  /// en el mismo lugar sin importar el largo del nombre. Si el texto del
  /// sistema es muy grande se reduce en vez de empujar a las demás columnas.
  static const double _balanceWidth = 84;

  @override
  Widget build(BuildContext context) {
    final balance = child.balance;
    final low = child.hasLowBalance;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: selected ? AppColors.secondary50 : Colors.transparent,
        borderRadius: AppRadius.controlAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ChildAvatar(child: child, radius: 22),
                const SizedBox(width: AppSpacing.md),
                // Dos columnas alineadas por la línea de base: nombre | monto y
                // colegio | "Saldo bajo". El nombre toma todo el espacio que
                // sobra y se corta con "…"; el saldo vive en una columna de
                // ancho fijo, así queda siempre en el mismo lugar.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.itemTitle,
                            ),
                            if (child.institutionName.isNotEmpty)
                              Text(
                                child.institutionName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.secondary,
                              ),
                          ],
                        ),
                      ),
                      if (balance != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: _balanceWidth,
                          child: _BalanceColumn(balance: balance, low: low),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _SelectionMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Monto y, si el saldo es bajo, "Saldo bajo", pegados a la derecha de una
/// columna de ancho fijo. Cada línea se reduce sola si no cabe.
class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({required this.balance, required this.low});

  final double balance;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final color = low ? AppColors.danger700 : AppColors.brand700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ShrinkRight(
          child: Text(
            '\$${balance.toStringAsFixed(2)}',
            maxLines: 1,
            style: AppText.rowTitle.copyWith(fontSize: 15, color: color),
          ),
        ),
        if (low)
          _ShrinkRight(
            child: Text(
              'Saldo bajo',
              maxLines: 1,
              style: AppText.badge.copyWith(
                fontSize: 11.5,
                color: AppColors.danger700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Alinea a la derecha y reduce el texto solo si no cabe en el ancho dado.
class _ShrinkRight extends StatelessWidget {
  const _ShrinkRight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: child,
    );
  }
}

/// Círculo morado con check cuando está elegido; anillo morado si no.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.secondary500 : null,
        border: selected
            ? null
            : Border.all(color: AppColors.secondary500, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
