import 'dart:math' as math;

import '../models/pos_identification_model.dart';
import '../models/sale_models.dart';
import 'payment_method_policy.dart';

/// What the cashier sees under the amount once a sale is registered: the line
/// that explains how it was paid and, when the customer has an account, what
/// is left of it. Pure rules, so the receipt sheet only paints.
class SaleReceiptSummary {
  const SaleReceiptSummary({
    required this.subtitle,
    required this.methodLabel,
    this.balanceLabel,
    this.balanceAmount,
  });

  final String subtitle;
  final String methodLabel;

  /// Null when there is no account figure to show (cash, quick sale).
  final String? balanceLabel;
  final double? balanceAmount;

  bool get hasBalance => balanceLabel != null && balanceAmount != null;

  /// [user] is the customer as identified before the sale, so its balance and
  /// credit are the ones from before [sale]; the backend discards the sale
  /// from them atomically.
  factory SaleReceiptSummary.of({
    required Sale sale,
    required PaymentMethod method,
    IdentifiedUser? user,
  }) {
    final methodLabel =
        PaymentMethodPolicy.optionFor(method)?.shortLabel ?? 'Pago';

    switch (method) {
      case PaymentMethod.wallet:
        return SaleReceiptSummary(
          subtitle: 'Se descontó del saldo de la billetera',
          methodLabel: methodLabel,
          balanceLabel: user == null
              ? null
              : _withName('Saldo restante', user.fullName),
          balanceAmount: user == null
              ? null
              : math.max(0, user.balance - sale.totalAmount),
        );
      case PaymentMethod.credit:
        final accumulated = user?.creditAccumulated;
        return SaleReceiptSummary(
          subtitle: 'Se sumó al crédito institucional',
          methodLabel: methodLabel,
          balanceLabel: accumulated == null ? null : 'Consumido este mes',
          balanceAmount: accumulated == null
              ? null
              : accumulated + sale.totalAmount,
        );
      case PaymentMethod.cash:
        return SaleReceiptSummary(
          subtitle: 'Cobro en efectivo',
          methodLabel: methodLabel,
        );
    }
  }

  static String _withName(String label, String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final firstName = words.first;
    return firstName.isEmpty ? label : '$label de $firstName';
  }
}
