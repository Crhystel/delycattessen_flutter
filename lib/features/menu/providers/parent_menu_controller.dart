import 'package:flutter/foundation.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../utils/cart_rules.dart';
import '../../../core/utils/error_message.dart';

/// Estado y reglas de la pantalla de menú del padre: carga del menú mensual,
/// día elegido, carrito y búsqueda. La pantalla solo pinta y pide confirmaciones.
class ParentMenuController extends ChangeNotifier {
  ParentMenuController({MenuService? menuService})
    : _menuService = menuService ?? MenuService();

  final MenuService _menuService;

  bool _isLoading = true;
  String? _errorMessage;
  List<MenuDay> _days = [];
  MenuDay? _selectedDay;
  final Map<int, int> _cart = {}; // dishId -> quantity
  String _searchQuery = '';

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// La carga del menú es asíncrona: si la pantalla ya se cerró, no notifica.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MenuDay> get days => _days;
  MenuDay? get selectedDay => _selectedDay;
  Map<int, int> get cart => Map.unmodifiable(_cart);
  bool get hasCart => _cart.isNotEmpty;
  String get searchQuery => _searchQuery;
  int get cartItemCount => CartRules.itemCount(_cart);

  /// Platillos del día elegido que coinciden con la búsqueda.
  List<MenuDish> get visibleDishes {
    final day = _selectedDay;
    if (day == null) return [];
    if (_searchQuery.isEmpty) return day.dishes;
    return day.dishes
        .where((d) => d.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  double get total {
    final dishes = _selectedDay?.dishes ?? const <MenuDish>[];
    return CartRules.total(_cart, (id) {
      final matches = dishes.where((d) => d.id == id);
      return matches.isEmpty ? null : matches.first.price;
    });
  }

  /// Para cuando no hay estudiante que consultar: deja de mostrar la carga.
  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  /// Carga el menú mensual del estudiante. Si [initialDate] existe en el menú
  /// se elige ese día; si no, el primero.
  Future<void> load(int studentId, {DateTime? initialDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final days = await _menuService.getStudentMonthlyMenu(studentId);

      MenuDay? targetDay;
      if (initialDate != null) {
        final initialIso = DateFormatter.toIsoDate(initialDate);
        targetDay = days.where((d) => d.date == initialIso).firstOrNull;
      }
      targetDay ??= days.isNotEmpty ? days.first : null;

      _days = days;
      _selectedDay = targetDay;
    } catch (e) {
      _errorMessage = errorMessageOf(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia de día; el carrito y la búsqueda son por día, así que se vacían.
  void selectDay(MenuDay day) {
    _selectedDay = day;
    _cart.clear();
    _searchQuery = '';
    notifyListeners();
  }

  void addToCart(int dishId, int quantity) {
    _cart[dishId] = (_cart[dishId] ?? 0) + quantity;
    notifyListeners();
  }

  void replaceCart(Map<int, int> cart) {
    _cart
      ..clear()
      ..addAll(cart);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void setSearchQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == _searchQuery) return;
    _searchQuery = normalized;
    notifyListeners();
  }
}
