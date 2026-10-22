import '../models/document_type.dart';
import '../models/wallet_models.dart';
import 'card_tokenizer.dart';
import 'kushki_service.dart';
import 'wallet_service.dart';

/// Lo que el usuario escribió en el formulario de tarjeta, sin formato de UI.
class CardFormData {
  final String cardNumber;
  final String holderName;
  final String expiration; // MM/AA
  final String cvv;
  final String phone;
  final String documentNumber;
  final DocumentType documentType;
  final bool acceptedTerms;

  const CardFormData({
    required this.cardNumber,
    required this.holderName,
    required this.expiration,
    required this.cvv,
    required this.phone,
    required this.documentNumber,
    required this.documentType,
    required this.acceptedTerms,
  });
}

/// Valida el formulario de tarjeta antes de enviarlo.
class CardFormValidator {
  CardFormValidator._();

  /// Mensaje del primer problema encontrado, o null si el formulario es válido.
  static String? validate(CardFormData data) {
    if (data.cardNumber.replaceAll(' ', '').length < 16 ||
        data.holderName.isEmpty ||
        data.expiration.length < 5 ||
        data.cvv.length < 3) {
      return 'Completa todos los campos de la tarjeta correctamente.';
    }
    if (data.phone.isEmpty || data.documentNumber.isEmpty) {
      return 'Ingresa tu teléfono y documento de identidad.';
    }
    if (!data.acceptedTerms) {
      return 'Debes aceptar los Términos y Condiciones.';
    }
    return null;
  }
}

/// Cómo terminó una recarga con tarjeta.
enum CardRechargeStatus {
  /// El saldo se acreditó.
  credited,

  /// La pasarela rechazó el cobro.
  rejected,

  /// Sigue pendiente tras agotar los intentos de consulta.
  timedOut,

  /// El backend respondió sin dejar el cobro en proceso (nada que consultar).
  submitted,

  /// La pantalla se cerró antes de conocer el resultado.
  cancelled,
}

/// Flujo de recarga con tarjeta: tokeniza, registra la recarga y consulta el
/// resultado hasta que se resuelve. No conoce la UI, así que se prueba solo.
class CardRechargeService {
  CardRechargeService({
    CardTokenizer? cardTokenizer,
    WalletService? walletService,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPollAttempts = 7,
  }) : _cardTokenizer = cardTokenizer ?? KushkiService(),
       _walletService = walletService ?? WalletService();

  final CardTokenizer _cardTokenizer;
  final WalletService _walletService;
  final Duration pollInterval;
  final int maxPollAttempts;

  /// Lanza una excepción con mensaje legible si falla la tokenización o el
  /// registro. [isCancelled] permite abortar la consulta si la pantalla se
  /// cerró mientras se esperaba.
  Future<CardRechargeStatus> recharge({
    required int walletId,
    required double amount,
    required CardFormData data,
    bool Function()? isCancelled,
  }) async {
    final expirationParts = data.expiration.split('/');
    final token = await _cardTokenizer.tokenizeCard(
      cardNumber: data.cardNumber,
      cvv: data.cvv,
      expiryMonth: expirationParts[0],
      expiryYear: expirationParts[1],
      holderName: data.holderName,
      amount: amount,
    );

    final response = await _walletService.recharge(
      RechargeRequest(
        walletId: walletId,
        amount: amount,
        kushkiToken: token,
        documentType: data.documentType.apiCode,
        documentNumber: data.documentNumber,
        phoneNumber: data.phone,
      ),
    );

    if (isCancelled?.call() ?? false) return CardRechargeStatus.cancelled;
    if (!response.isProcessingAsync) return CardRechargeStatus.submitted;
    return _pollUntilResolved(walletId, isCancelled);
  }

  Future<CardRechargeStatus> _pollUntilResolved(
    int walletId,
    bool Function()? isCancelled,
  ) async {
    for (var i = 0; i < maxPollAttempts; i++) {
      await Future.delayed(pollInterval);
      if (isCancelled?.call() ?? false) return CardRechargeStatus.cancelled;
      try {
        final transactions = await _walletService.getTransactions(walletId);
        final latest = transactions.isNotEmpty ? transactions.first : null;
        if (latest != null && latest.status != 'pending') {
          return latest.status == 'success'
              ? CardRechargeStatus.credited
              : CardRechargeStatus.rejected;
        }
      } catch (_) {
        // Falla transitoria de red: se reintenta en el siguiente intento.
      }
    }
    return CardRechargeStatus.timedOut;
  }
}
