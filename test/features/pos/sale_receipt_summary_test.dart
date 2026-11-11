import 'package:delycattessen_flutter/features/pos/models/pos_identification_model.dart';
import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/utils/sale_receipt_summary.dart';
import 'package:flutter_test/flutter_test.dart';

IdentifiedUser _user({
  String role = 'STUDENT',
  String name = 'Julieta Venegas',
  double balance = 9,
  double? credit,
}) => IdentifiedUser(
  userId: 1,
  username: 'julieta',
  fullName: name,
  role: role,
  roleDisplay: role,
  balance: balance,
  creditAccumulated: credit,
  allergies: const [],
  pendingOrders: const [],
  identificationMethod: 'QR',
);

Sale _sale(PaymentMethod method, double total) => Sale(
  id: 1,
  paymentMethod: method,
  totalAmount: total,
  createdAt: DateTime(2026, 11, 11),
  displayName: 'Helado',
  time: '10:00',
  items: const [],
);

SaleReceiptSummary _summary(
  PaymentMethod method,
  double total, {
  IdentifiedUser? user,
}) => SaleReceiptSummary.of(
  sale: _sale(method, total),
  method: method,
  user: user,
);

void main() {
  group('wallet', () {
    test('subtracts the sale from the balance the customer had', () {
      final summary = _summary(PaymentMethod.wallet, 1, user: _user());

      expect(summary.subtitle, 'Se descontó del saldo de la billetera');
      expect(summary.methodLabel, 'Billetera');
      expect(summary.balanceLabel, 'Saldo restante de Julieta');
      expect(summary.balanceAmount, 8);
    });

    test('never shows a negative balance', () {
      final summary = _summary(
        PaymentMethod.wallet,
        5,
        user: _user(balance: 3),
      );

      expect(summary.balanceAmount, 0);
    });

    test('names the customer by first name only', () {
      final summary = _summary(
        PaymentMethod.wallet,
        1,
        user: _user(name: '  Ana   María Pérez '),
      );

      expect(summary.balanceLabel, 'Saldo restante de Ana');
    });

    test('drops the name when the customer has none', () {
      final summary = _summary(PaymentMethod.wallet, 1, user: _user(name: ''));

      expect(summary.balanceLabel, 'Saldo restante');
    });

    test('has no balance line without an identified customer', () {
      final summary = _summary(PaymentMethod.wallet, 1);

      expect(summary.hasBalance, isFalse);
    });
  });

  group('credit', () {
    test('adds the sale to what the teacher consumed this month', () {
      final summary = _summary(
        PaymentMethod.credit,
        2.5,
        user: _user(role: 'TEACHER', credit: 10),
      );

      expect(summary.subtitle, 'Se sumó al crédito institucional');
      expect(summary.methodLabel, 'Crédito');
      expect(summary.balanceLabel, 'Consumido este mes');
      expect(summary.balanceAmount, 12.5);
    });

    test('has no balance line when the backend sent no credit', () {
      final summary = _summary(
        PaymentMethod.credit,
        2.5,
        user: _user(role: 'TEACHER'),
      );

      expect(summary.hasBalance, isFalse);
    });
  });

  group('cash', () {
    test('has no balance line with or without a customer', () {
      expect(_summary(PaymentMethod.cash, 3).hasBalance, isFalse);
      expect(
        _summary(PaymentMethod.cash, 3, user: _user()).hasBalance,
        isFalse,
      );
    });

    test('says it was a cash sale', () {
      final summary = _summary(PaymentMethod.cash, 3);

      expect(summary.subtitle, 'Cobro en efectivo');
      expect(summary.methodLabel, 'Efectivo');
    });
  });
}
