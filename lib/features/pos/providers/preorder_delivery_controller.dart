import 'package:flutter/foundation.dart';

import '../services/pos_service.dart';

/// Estado de la entrega de preórdenes pendientes de un usuario identificado:
/// cuáles ya se entregaron y cuál se está confirmando.
class PreOrderDeliveryController extends ChangeNotifier {
  PreOrderDeliveryController({PosService? posService})
    : _posService = posService ?? PosService();

  final PosService _posService;
  final Set<int> _deliveredIds = {};
  int? _submittingId;
  bool _disposed = false;

  bool isDelivered(int preOrderId) => _deliveredIds.contains(preOrderId);
  bool isSubmitting(int preOrderId) => _submittingId == preOrderId;

  /// Marca la preorden como entregada. Devuelve null si salió bien o el
  /// mensaje de error legible si falló.
  Future<String?> markAsDelivered(int preOrderId) async {
    _submittingId = preOrderId;
    notifyListeners();
    try {
      await _posService.markPreOrderDelivered(preOrderId);
      _deliveredIds.add(preOrderId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _submittingId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// La confirmación es asíncrona: si la hoja ya se cerró, no notifica.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
