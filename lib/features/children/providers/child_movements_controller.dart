import 'package:flutter/foundation.dart';

import '../../../core/utils/error_message.dart';
import '../../wallet/models/wallet_models.dart';
import '../../wallet/services/wallet_service.dart';

enum ChildMovementsStatus { loading, ready, error }

/// Los últimos movimientos de la billetera de un hijo para la ficha. Pide la
/// lista completa al backend y se queda con los más recientes.
class ChildMovementsController extends ChangeNotifier {
  ChildMovementsController({
    required this.walletId,
    WalletService? walletService,
    this.limit = defaultLimit,
  }) : _walletService = walletService ?? WalletService();

  static const int defaultLimit = 3;

  final int walletId;
  final int limit;
  final WalletService _walletService;

  ChildMovementsStatus _status = ChildMovementsStatus.loading;
  List<TransactionModel> _items = const [];
  String? _errorMessage;
  bool _disposed = false;

  ChildMovementsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Los movimientos más recientes primero, hasta [limit].
  List<TransactionModel> get items => _items;

  Future<void> load() async {
    _status = ChildMovementsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final all = await _walletService.getTransactions(walletId);
      if (_disposed) return;
      _items = latest(all, limit);
      _status = ChildMovementsStatus.ready;
    } catch (e) {
      if (_disposed) return;
      _errorMessage = errorMessageOf(e);
      _status = ChildMovementsStatus.error;
    }
    notifyListeners();
  }

  /// Los [count] movimientos más recientes de [transactions], del más nuevo al
  /// más viejo (no depende del orden en que los envíe el backend).
  static List<TransactionModel> latest(
    List<TransactionModel> transactions,
    int count,
  ) {
    final sorted = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(count).toList(growable: false);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
