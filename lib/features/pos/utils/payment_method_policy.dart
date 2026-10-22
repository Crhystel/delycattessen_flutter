import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../models/pos_identification_model.dart';
import '../models/sale_models.dart';

/// Presentación de un método de pago en el checkout.
class PaymentMethodOption {
  final PaymentMethod method;
  final String label;
  final String description;
  final IconData icon;

  const PaymentMethodOption({
    required this.method,
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Qué métodos de pago se ofrecen según quién compra. Es solo una guía de UI:
/// la validación autoritativa vive en el backend (`SaleProcessor`). Para
/// sumar un método basta una entrada en [_options] y en [_allowedRoles].
class PaymentMethodPolicy {
  PaymentMethodPolicy._();

  static const Map<PaymentMethod, PaymentMethodOption> _options = {
    PaymentMethod.wallet: PaymentMethodOption(
      method: PaymentMethod.wallet,
      label: 'Saldo de billetera',
      description: 'Se descuenta del saldo del estudiante.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    PaymentMethod.credit: PaymentMethodOption(
      method: PaymentMethod.credit,
      label: 'Crédito institucional',
      description: 'Se acumula a nombre del docente en el mes.',
      icon: Icons.account_balance_outlined,
    ),
    PaymentMethod.cash: PaymentMethodOption(
      method: PaymentMethod.cash,
      label: 'Efectivo',
      description: 'El cliente paga en caja.',
      icon: Icons.payments_outlined,
    ),
  };

  /// Roles que pueden usar cada método con cliente identificado.
  /// Efectivo no exige rol (sin cliente = venta rápida).
  static const Map<PaymentMethod, Set<UserRole>> _allowedRoles = {
    PaymentMethod.credit: {UserRole.teacher},
    PaymentMethod.wallet: {UserRole.student},
  };

  /// Datos de presentación de [method] (null si no está registrado).
  static PaymentMethodOption? optionFor(PaymentMethod method) =>
      _options[method];

  /// Métodos ofrecidos para [user] (null = venta rápida, solo efectivo).
  static List<PaymentMethodOption> availableFor(IdentifiedUser? user) {
    return [
      for (final entry in _options.entries)
        if (_isAllowed(entry.key, user)) entry.value,
    ];
  }

  static bool _isAllowed(PaymentMethod method, IdentifiedUser? user) {
    final roles = _allowedRoles[method];
    if (roles == null) return true; // sin restricción de rol (efectivo)
    return user != null && roles.contains(user.userRole);
  }

  /// Método sugerido al abrir el checkout: el propio del cliente (saldo o
  /// crédito) si existe; si no, efectivo.
  static PaymentMethod defaultFor(IdentifiedUser? user) {
    final options = availableFor(user);
    if (options.isEmpty) return PaymentMethod.cash;
    return options.first.method;
  }
}
