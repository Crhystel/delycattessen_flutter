import 'package:flutter/material.dart';

import '../models/recharge_gateway.dart';
import '../models/wallet_models.dart';
import '../screens/payphone_webview_screen.dart';
import '../screens/recharge_card_form_screen.dart';
import '../services/card_tokenizer.dart';
import '../services/wallet_service.dart';

/// Datos de la recarga que cada pasarela necesita para arrancar.
class RechargeRequestData {
  final int walletId;
  final String childName;
  final double amount;

  const RechargeRequestData({
    required this.walletId,
    required this.childName,
    required this.amount,
  });
}

/// Estrategia por pasarela: abre su flujo y devuelve true si el saldo se
/// acreditó. Agregar una pasarela = un valor en [RechargeGateway] y un
/// launcher aquí; la pantalla de recarga no cambia.
abstract class RechargeLauncher {
  Future<bool> start(BuildContext context, RechargeRequestData data);
}

/// Payphone: el backend prepara el pago y devuelve la página a abrir.
class PayphoneRechargeLauncher implements RechargeLauncher {
  final WalletService _walletService;

  PayphoneRechargeLauncher({WalletService? walletService})
    : _walletService = walletService ?? WalletService();

  @override
  Future<bool> start(BuildContext context, RechargeRequestData data) async {
    final response = await _walletService.recharge(
      RechargeRequest(walletId: data.walletId, amount: data.amount),
    );
    final paymentUrl = response.paymentUrl;
    if (paymentUrl == null) {
      throw Exception('No se pudo iniciar el pago con Payphone.');
    }
    if (!context.mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayphoneWebViewScreen(paymentUrl: paymentUrl),
      ),
    );
    return result == true;
  }
}

/// Kushki: el formulario de tarjeta tokeniza y registra la recarga.
class KushkiRechargeLauncher implements RechargeLauncher {
  final WalletService? walletService;
  final CardTokenizer? cardTokenizer;

  KushkiRechargeLauncher({this.walletService, this.cardTokenizer});

  @override
  Future<bool> start(BuildContext context, RechargeRequestData data) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RechargeCardFormScreen(
          walletId: data.walletId,
          childName: data.childName,
          amount: data.amount,
          walletService: walletService,
          cardTokenizer: cardTokenizer,
        ),
      ),
    );
    return result == true;
  }
}

/// Único lugar que relaciona cada pasarela con su flujo.
class RechargeLaunchers {
  RechargeLaunchers._();

  static final Map<RechargeGateway, RechargeLauncher> _byGateway = {
    RechargeGateway.payphone: PayphoneRechargeLauncher(),
    RechargeGateway.kushki: KushkiRechargeLauncher(),
  };

  static RechargeLauncher forGateway(RechargeGateway gateway) =>
      _byGateway[gateway]!;
}
