import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child(int id, {int? walletId}) => Child(
  id: id,
  firstName: 'Child$id',
  lastName: 'Test',
  institutionName: 'School',
  walletId: walletId,
);

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._children);

  List<Child> _children;
  Object? error;
  int calls = 0;

  set children(List<Child> value) => _children = value;

  @override
  Future<List<Child>> getChildren() async {
    calls++;
    if (error != null) throw error!;
    return _children;
  }
}

void main() {
  group('ChildrenProvider', () {
    test('ensureLoaded fetches once and then uses the cache', () async {
      final service = _FakeAuthService([_child(1)]);
      final provider = ChildrenProvider(authService: service);

      await provider.ensureLoaded();
      await provider.ensureLoaded();

      expect(service.calls, 1);
      expect(provider.hasLoadedOnce, isTrue);
      expect(provider.children, hasLength(1));
    });

    test('ensureLoaded(force: true) reloads from the backend', () async {
      final service = _FakeAuthService([_child(1)]);
      final provider = ChildrenProvider(authService: service);

      await provider.ensureLoaded();
      await provider.ensureLoaded(force: true);

      expect(service.calls, 2);
    });

    test('selectedChild falls back to the first child', () async {
      final provider = ChildrenProvider(
        authService: _FakeAuthService([_child(1), _child(2)]),
      );
      await provider.refresh();

      expect(provider.selectedChild?.id, 1);
      provider.select(2);
      expect(provider.selectedChild?.id, 2);
    });

    test(
      'selectedChild falls back when the selected child disappears',
      () async {
        final service = _FakeAuthService([_child(1), _child(2)]);
        final provider = ChildrenProvider(authService: service);
        await provider.refresh();
        provider.select(2);

        service.children = [_child(1)];
        await provider.refresh();

        expect(provider.selectedChild?.id, 1);
      },
    );

    test('select notifies only when the selection changes', () async {
      final provider = ChildrenProvider(
        authService: _FakeAuthService([_child(1), _child(2)]),
      );
      await provider.refresh();

      var notifications = 0;
      provider.addListener(() => notifications++);
      provider.select(2);
      provider.select(2);

      expect(notifications, 1);
    });

    test('childrenWithWallet keeps only children that have a wallet', () async {
      final provider = ChildrenProvider(
        authService: _FakeAuthService([_child(1, walletId: 10), _child(2)]),
      );
      await provider.refresh();

      expect(provider.childrenWithWallet.map((c) => c.id), [1]);
    });

    test('refresh stores a clean error message and stops loading', () async {
      final service = _FakeAuthService([])..error = Exception('Sin conexión');
      final provider = ChildrenProvider(authService: service);

      await provider.refresh();

      expect(provider.errorMessage, 'Sin conexión');
      expect(provider.isLoading, isFalse);
      expect(provider.hasLoadedOnce, isFalse);
    });
  });
}
