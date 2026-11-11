import 'package:delycattessen_flutter/features/menu/utils/orders_reload_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrdersReloadPolicy', () {
    late DateTime now;
    late OrdersReloadPolicy policy;

    setUp(() {
      now = DateTime(2026, 11, 10, 9);
      policy = OrdersReloadPolicy(clock: () => now);
    });

    test('reloads when nothing has been loaded yet', () {
      expect(policy.shouldReload, isTrue);
    });

    test('does not reload while the data is fresh', () {
      policy.markLoaded();
      now = now.add(const Duration(seconds: 29));

      expect(policy.shouldReload, isFalse);
    });

    test('reloads once the data is 30 seconds old', () {
      policy.markLoaded();
      now = now.add(const Duration(seconds: 30));

      expect(policy.shouldReload, isTrue);
    });

    test('an invalidation forces a reload even if the data is fresh', () {
      policy.markLoaded();
      policy.invalidate();

      expect(policy.shouldReload, isTrue);
    });

    test('a successful load clears the invalidation', () {
      policy.invalidate();
      policy.markLoaded();

      expect(policy.shouldReload, isFalse);
    });
  });

  test('OrdersReloadSignal notifies its listeners', () {
    var calls = 0;
    void listener() => calls++;
    OrdersReloadSignal.listenable.addListener(listener);
    addTearDown(() => OrdersReloadSignal.listenable.removeListener(listener));

    OrdersReloadSignal.request();

    expect(calls, 1);
  });
}
