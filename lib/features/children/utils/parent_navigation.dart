import 'package:flutter/material.dart';

/// Pedido de abrir la pestaña Billetera en "Movimientos" (de [childId], si se
/// da). Cada pedido es una instancia nueva, así dos seguidos para el mismo hijo
/// también avisan.
class WalletMovementsRequest {
  final int? childId;

  const WalletMovementsRequest(this.childId);
}

/// Pedido de abrir la pestaña Billetera en "Recargar" (a [childId], si se da).
/// Igual que [WalletMovementsRequest]: cada pedido es una instancia nueva.
class WalletRechargeRequest {
  final int? childId;

  const WalletRechargeRequest(this.childId);
}

/// Redirecciones hacia las pestañas del padre desde pantallas apiladas.
///
/// Los movimientos y la recarga tienen una sola vista: las secciones
/// "Movimientos" y "Recargar" de la pestaña Billetera. Las demás pantallas
/// (ficha del hijo, detalle de un pedido) no tienen la suya: cierran lo que haya
/// sobre el `ParentShell` y le piden que abra esa sección.
class ParentNavigation {
  ParentNavigation._();

  /// El `ParentShell` escucha este aviso y cambia de pestaña.
  static final ValueNotifier<WalletMovementsRequest?> walletMovements =
      ValueNotifier<WalletMovementsRequest?>(null);

  /// Igual, para la sección "Recargar".
  static final ValueNotifier<WalletRechargeRequest?> walletRecharge =
      ValueNotifier<WalletRechargeRequest?>(null);

  /// Vuelve al `ParentShell` y abre Billetera > Recargar a [childId].
  static void openWalletRecharge(BuildContext context, {int? childId}) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    walletRecharge.value = WalletRechargeRequest(childId);
  }

  /// Vuelve al `ParentShell` (la primera ruta tras iniciar sesión) y abre
  /// Billetera > Movimientos del hijo [childId].
  static void openWalletMovements(BuildContext context, {int? childId}) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    walletMovements.value = WalletMovementsRequest(childId);
  }
}
