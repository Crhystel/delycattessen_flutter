import 'package:flutter/foundation.dart';

/// Decide cuándo la pestaña Pedidos debe volver a pedir sus datos al backend.
///
/// La pestaña se reactiva cada vez que el usuario la abre; sin esta regla cada
/// visita disparaba dos peticiones aunque nada hubiera cambiado. Recarga solo
/// si pasó [minAge] desde la última carga correcta, si algo la invalidó (otro
/// hijo, una compra nueva) o si todavía no cargó nunca.
class OrdersReloadPolicy {
  OrdersReloadPolicy({
    this.minAge = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Antigüedad a partir de la cual los datos se consideran viejos.
  final Duration minAge;
  final DateTime Function() _clock;

  DateTime? _lastLoadedAt;
  bool _invalidated = false;

  /// true si hay que pedir los datos de nuevo.
  bool get shouldReload {
    final last = _lastLoadedAt;
    if (last == null || _invalidated) return true;
    return _clock().difference(last) >= minAge;
  }

  /// Registra una carga correcta: los datos quedan frescos.
  void markLoaded() {
    _lastLoadedAt = _clock();
    _invalidated = false;
  }

  /// Marca los datos como viejos (cambió el hijo, hubo una compra).
  void invalidate() => _invalidated = true;
}

/// Aviso global de "los pedidos cambiaron" (por ejemplo, tras confirmar una
/// compra desde el carrito). La pestaña Pedidos se suscribe y recarga en cuanto
/// esté visible, sin esperar a que pasen los 30 s de [OrdersReloadPolicy].
class OrdersReloadSignal {
  OrdersReloadSignal._();

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  static Listenable get listenable => _revision;

  /// Pide a la pestaña Pedidos que recargue la próxima vez que se muestre.
  static void request() => _revision.value++;
}
