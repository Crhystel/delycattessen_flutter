import 'package:delycattessen_flutter/features/pos/providers/preorder_delivery_controller.dart';
import 'package:delycattessen_flutter/features/pos/services/pos_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePosService extends PosService {
  Object? error;
  final delivered = <int>[];

  @override
  Future<void> markPreOrderDelivered(int preOrderId) async {
    if (error != null) throw error!;
    delivered.add(preOrderId);
  }
}

void main() {
  test('marks a pre-order as delivered and reports no error', () async {
    final service = _FakePosService();
    final controller = PreOrderDeliveryController(posService: service);

    final error = await controller.markAsDelivered(5);

    expect(error, isNull);
    expect(service.delivered, [5]);
    expect(controller.isDelivered(5), isTrue);
    expect(controller.isSubmitting(5), isFalse);
  });

  test('flags the pre-order as submitting while it is confirmed', () async {
    final controller = PreOrderDeliveryController(
      posService: _FakePosService(),
    );
    final seen = <bool>[];
    controller.addListener(() => seen.add(controller.isSubmitting(5)));

    await controller.markAsDelivered(5);

    expect(seen, [true, false]);
  });

  test('returns a clean message and keeps it pending when it fails', () async {
    final service = _FakePosService()..error = Exception('Ya fue entregado');
    final controller = PreOrderDeliveryController(posService: service);

    final error = await controller.markAsDelivered(5);

    expect(error, 'Ya fue entregado');
    expect(controller.isDelivered(5), isFalse);
    expect(controller.isSubmitting(5), isFalse);
  });

  test('does not notify after being disposed', () async {
    final controller = PreOrderDeliveryController(
      posService: _FakePosService(),
    );
    final result = controller.markAsDelivered(5);
    controller.dispose();

    await expectLater(result, completion(isNull));
  });
}
