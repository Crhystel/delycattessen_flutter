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

  Object? removeError;
  final List<(int, String)> removals = [];

  @override
  Future<void> removeChild(int studentId, String parentPassword) async {
    removals.add((studentId, parentPassword));
    if (removeError != null) throw removeError!;
    _children = _children.where((c) => c.id != studentId).toList();
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

    group('removeChild', () {
      test(
        'drops the child, sends the password and refreshes the rest',
        () async {
          final service = _FakeAuthService([_child(1), _child(2)]);
          final provider = ChildrenProvider(authService: service);
          await provider.refresh();

          await provider.removeChild(1, parentPassword: 'Parent-Passw0rd!');

          expect(service.removals, [(1, 'Parent-Passw0rd!')]);
          expect(provider.children.map((c) => c.id), [2]);
          expect(service.calls, 2); // the first load and the refresh after it
        },
      );

      test('selects another child when the selected one is removed', () async {
        final provider = ChildrenProvider(
          authService: _FakeAuthService([_child(1), _child(2)]),
        );
        await provider.refresh();
        provider.select(2);

        await provider.removeChild(2, parentPassword: 'x');

        expect(provider.selectedChild?.id, 1);
      });

      test('keeps the selection of a child that stays', () async {
        final provider = ChildrenProvider(
          authService: _FakeAuthService([_child(1), _child(2)]),
        );
        await provider.refresh();
        provider.select(2);

        await provider.removeChild(1, parentPassword: 'x');

        expect(provider.selectedChild?.id, 2);
      });

      test('the last child leaves the list as not loaded yet', () async {
        final service = _FakeAuthService([_child(1)]);
        final provider = ChildrenProvider(authService: service);
        await provider.refresh();

        await provider.removeChild(1, parentPassword: 'x');

        expect(provider.children, isEmpty);
        expect(provider.hasLoadedOnce, isFalse);
        expect(provider.selectedChild, isNull);
        expect(service.calls, 1); // nothing to refresh
      });

      test('a rejected removal leaves the list as it was', () async {
        final service = _FakeAuthService([_child(1), _child(2)])
          ..removeError = Exception('Tu contraseña es incorrecta.');
        final provider = ChildrenProvider(authService: service);
        await provider.refresh();

        await expectLater(
          provider.removeChild(1, parentPassword: 'mala'),
          throwsA(isA<Exception>()),
        );

        expect(provider.children.map((c) => c.id), [1, 2]);
      });

      test('a load in flight cannot bring the removed child back', () async {
        final service = _FakeAuthService([_child(1), _child(2)]);
        final provider = ChildrenProvider(authService: service);
        await provider.refresh();

        // This load started before the removal, so it still has both children.
        final stale = provider.refresh();
        await provider.removeChild(1, parentPassword: 'x');
        await stale;

        expect(provider.children.map((c) => c.id), [2]);
        expect(provider.isLoading, isFalse);
      });
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
