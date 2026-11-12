import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/utils/error_message.dart';

/// Centraliza la lista de hijos del padre autenticado. Antes, cada pantalla
/// (ChildrenList, Menu, Wallet, Orders) pedía getChildren() por su cuenta
/// cada vez que se navegaba entre ellas por el bottom nav; ahora se carga
/// una sola vez y se comparte, y solo se vuelve a pedir cuando algo la
/// invalida explícitamente (registrar un hijo, recargar saldo, pull-to-refresh).
///
/// Se vacía sola cuando termina la sesión ([SessionManager.sessionEnded]) para
/// que otra cuenta en el mismo dispositivo no vea los hijos de la anterior.
class ChildrenProvider extends ChangeNotifier {
  ChildrenProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    SessionManager.sessionEnded.addListener(reset);
  }

  final AuthService _authService;

  List<Child> _children = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  int? _selectedChildId;

  /// Carga en curso, compartida: dos pantallas que piden refrescar a la vez
  /// (p. ej. al volver de otra) esperan la misma petición en vez de duplicarla.
  Future<void>? _refreshInFlight;

  /// Se incrementa en cada [reset] para descartar respuestas que llegan
  /// después de cerrar la sesión.
  int _generation = 0;

  UnmodifiableListView<Child> get children => UnmodifiableListView(_children);
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

  /// Fuerza una recarga desde el backend. Si ya hay una en curso, devuelve esa.
  Future<void> refresh() {
    return _refreshInFlight ??= _load().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<void> _load() async {
    final generation = _generation;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loaded = await _authService.getChildren();
      if (generation != _generation) return;
      _children = loaded;
      _hasLoadedOnce = true;
    } catch (e) {
      if (generation != _generation) return;
      _errorMessage = errorMessageOf(e);
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Da de baja a [childId] (el padre confirma con su contraseña) y lo saca de
  /// la lista. Si quedan hijos se refresca la lista; si no, queda como sin
  /// cargar para que un hijo nuevo se pida de cero. Lanza lo que lance el
  /// service (contraseña errónea, condiciones sin cumplir, red).
  Future<void> removeChild(
    int childId, {
    required String parentPassword,
  }) async {
    await _authService.removeChild(childId, parentPassword);
    // Una carga en vuelo podría traer todavía al hijo dado de baja.
    _generation++;
    _refreshInFlight = null;
    _isLoading = false;
    _children = _children.where((child) => child.id != childId).toList();
    if (_selectedChildId == childId) _selectedChildId = null;
    if (_children.isEmpty) _hasLoadedOnce = false;
    notifyListeners();
    if (_children.isNotEmpty) refresh();
  }

  /// Olvida todo lo de la cuenta anterior (cierre de sesión).
  void reset() {
    _generation++;
    _children = [];
    _isLoading = false;
    _errorMessage = null;
    _hasLoadedOnce = false;
    _selectedChildId = null;
    _refreshInFlight = null;
    notifyListeners();
  }

  @override
  void dispose() {
    SessionManager.sessionEnded.removeListener(reset);
    super.dispose();
  }
}
