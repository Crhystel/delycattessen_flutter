import 'package:flutter/foundation.dart';

import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';

/// Centraliza la lista de hijos del padre autenticado. Antes, cada pantalla
/// (ChildrenList, Menu, Wallet, Orders) pedía getChildren() por su cuenta
/// cada vez que se navegaba entre ellas por el bottom nav; ahora se carga
/// una sola vez y se comparte, y solo se vuelve a pedir cuando algo la
/// invalida explícitamente (registrar un hijo, recargar saldo, pull-to-refresh).
class ChildrenProvider extends ChangeNotifier {
  ChildrenProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  List<Child> _children = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  int? _selectedChildId;

  List<Child> get children => List.unmodifiable(_children);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedOnce => _hasLoadedOnce;

  Child? get firstChild => _children.isNotEmpty ? _children.first : null;

  /// Hijo "activo" compartido por Menú, Pedidos y Billetera. Si todavía no
  /// se eligió uno (o ya no existe tras una recarga) cae en el primero.
  Child? get selectedChild {
    if (_children.isEmpty) return null;
    return _children.firstWhere(
      (c) => c.id == _selectedChildId,
      orElse: () => _children.first,
    );
  }

  void select(int childId) {
    if (_selectedChildId == childId) return;
    _selectedChildId = childId;
    notifyListeners();
  }

  List<Child> get childrenWithWallet =>
      _children.where((c) => c.walletId != null).toList();

  /// Carga los hijos solo si todavía no se han cargado (o si [force] es
  /// true). Las pantallas la llaman en initState para asegurarse de tener
  /// datos sin forzar una llamada de red si ya están en caché.
  Future<void> ensureLoaded({bool force = false}) async {
    if (_hasLoadedOnce && !force) return;
    await refresh();
  }

  /// Fuerza una recarga desde el backend.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _children = await _authService.getChildren();
      _hasLoadedOnce = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
