import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/allergy_models.dart';

/// Contenido de "Alergias" con el estilo del rediseño del padre: tarjeta de
/// "Registradas" con chips rojos, tarjeta "Añadir una alergia" y el aviso
/// ámbar. Solo pinta: el estado y el guardado viven en
/// `AllergyManagementScreen`.
class ParentAllergyForm extends StatelessWidget {
  const ParentAllergyForm({
    super.key,
    required this.registered,
    required this.available,
    required this.selectedToAdd,
    required this.onSelectedToAddChanged,
    required this.onAdd,
    required this.onRemove,
    required this.showNewAllergenField,
    required this.onShowNewAllergenField,
    required this.newAllergenForm,
    required this.firstName,
  });

  final List<Allergen> registered;
  final List<Allergen> available;
  final Allergen? selectedToAdd;
  final ValueChanged<Allergen?> onSelectedToAddChanged;
  final VoidCallback onAdd;
  final ValueChanged<Allergen> onRemove;
  final bool showNewAllergenField;
  final VoidCallback onShowNewAllergenField;

  /// Formulario para crear una alergia nueva (lo arma la pantalla).
  final Widget newAllergenForm;

  /// Nombre de pila de quien se registra, para el aviso del final.
  final String firstName;

  /// Separación entre tarjetas y dentro de ellas.
  static const double _gap = 14;
  static const double _innerGap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegisteredCard(registered: registered, onRemove: onRemove),
        const SizedBox(height: _gap),
        AppCard(
          design: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Añadir una alergia', style: AppText.cardTitle),
              const SizedBox(height: _innerGap),
              _AllergenSelector(
                value: selectedToAdd,
                items: available,
                onChanged: onSelectedToAddChanged,
              ),
              const SizedBox(height: _innerGap),
              _AddButton(onPressed: selectedToAdd == null ? null : onAdd),
              const SizedBox(height: _innerGap),
              if (!showNewAllergenField)
                Center(
                  child: TextButton(
                    onPressed: onShowNewAllergenField,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: AppColors.secondary500,
                    ),
                    child: Text(
                      '¿No encuentras la alergia? Agrégala',
                      style: AppText.link,
                    ),
                  ),
                )
              else
                newAllergenForm,
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _WarningNote(firstName: firstName),
      ],
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard({required this.registered, required this.onRemove});

  final List<Allergen> registered;
  final ValueChanged<Allergen> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      design: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Registradas', style: AppText.cardTitle)),
              const SizedBox(width: AppSpacing.sm),
              Text('${registered.length}', style: AppText.secondaryLg),
            ],
          ),
          const SizedBox(height: ParentAllergyForm._innerGap),
          if (registered.isEmpty)
            Text(
              'Aún no hay alergias registradas. Elige una de la lista para '
              'agregarla.',
              style: AppText.secondaryLg,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final allergen in registered)
                  _AllergenChip(
                    name: allergen.name,
                    onRemove: () => onRemove(allergen),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chip rojo de una alergia registrada: 40 de alto, "x" de 32 para quitarla.
class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: 6),
      decoration: const BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.rowTitle.copyWith(
                fontSize: 15,
                color: AppColors.danger700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: 'Quitar ${name.toLowerCase()}',
            child: InkResponse(
              onTap: onRemove,
              radius: 16,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.close, size: 15, color: AppColors.danger700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de alergia: 52 de alto, borde morado de 1.5 y chevron morado.
class _AllergenSelector extends StatelessWidget {
  const _AllergenSelector({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final Allergen? value;
  final List<Allergen> items;
  final ValueChanged<Allergen?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppText.rowTitle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.fieldAll,
        border: Border.all(color: AppColors.secondary500, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Allergen>(
          value: value,
          isExpanded: true,
          style: textStyle,
          dropdownColor: Colors.white,
          borderRadius: AppRadius.fieldAll,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 24,
            color: AppColors.secondary500,
          ),
          hint: Text(
            'Selecciona una alergia',
            style: textStyle.copyWith(color: AppColors.placeholder),
          ),
          items: [
            for (final allergen in items)
              DropdownMenuItem(value: allergen, child: Text(allergen.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// "Añadir": relleno suave (`secondary50`) con texto morado mientras no haya
/// una alergia elegida; morado sólido cuando se puede añadir.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.secondary50,
          disabledForegroundColor: AppColors.secondary500,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.add, size: 18),
        // Sin color propio: lo toma del botón (morado sobre `secondary50`).
        label: const Text(
          'Añadir',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Aviso ámbar del final (radio 18, sin borde izquierdo).
class _WarningNote extends StatelessWidget {
  const _WarningNote({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: ParentAllergyForm._gap,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: AppColors.brand700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los platos y productos que contengan estas alergias se '
              'marcarán en el menú cuando pidas para $firstName.',
              style: AppText.rowTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brand700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior fija con "Guardar cambios": fondo `ink50`, borde superior
/// `line` y botón de 54. Respeta la barra de gestos del sistema.
class ParentAllergySaveBar extends StatelessWidget {
  const ParentAllergySaveBar({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  /// Margen inferior del diseño (incluye la zona de la barra de gestos).
  static const double _bottom = 26;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.ink50,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              14,
              AppSpacing.page,
              math.max(_bottom, inset + AppSpacing.md),
            ),
            child: PrimaryButton(
              design: true,
              label: 'Guardar cambios',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: onSave,
            ),
          ),
        ),
      ),
    );
  }
}
