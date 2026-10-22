import 'package:delycattessen_flutter/features/wallet/models/document_type.dart';
import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/services/card_recharge_service.dart';
import 'package:delycattessen_flutter/features/wallet/services/card_tokenizer.dart';
import 'package:delycattessen_flutter/features/wallet/services/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

CardFormData _data({
  String cardNumber = '4111 1111 1111 1111',
  String holderName = 'Test User',
  String expiration = '12/30',
  String cvv = '123',
  String phone = '0999999999',
  String documentNumber = '1700000000',
  bool acceptedTerms = true,
}) => CardFormData(
  cardNumber: cardNumber,
  holderName: holderName,
  expiration: expiration,
  cvv: cvv,
  phone: phone,
  documentNumber: documentNumber,
  documentType: DocumentType.cedula,
  acceptedTerms: acceptedTerms,
);

class _FakeTokenizer implements CardTokenizer {
  String? expiryMonth;
  String? expiryYear;

  @override
  Future<String> tokenizeCard({
    required String cardNumber,
    required String cvv,
    required String expiryMonth,
    required String expiryYear,
    required String holderName,
    required double amount,
  }) async {
    this.expiryMonth = expiryMonth;
    this.expiryYear = expiryYear;
    return 'tok_test';
  }
}

TransactionModel _transaction(String status) => TransactionModel(
  id: 1,
  displayName: 'Recarga',
  amount: 5,
  gateway: 'kushki',
  status: status,
  type: 'recharge',
  time: '10:00',
  createdAt: DateTime(2026, 1, 1),
  items: const [],
);

class _FakeWalletService extends WalletService {
  _FakeWalletService({required this.response, this.statuses = const []});

  final RechargeResponse response;
  final List<String> statuses;
  RechargeRequest? sentRequest;
  int polls = 0;

  @override
  Future<RechargeResponse> recharge(RechargeRequest request) async {
    sentRequest = request;
    return response;
  }

  @override
  Future<List<TransactionModel>> getTransactions(int walletId) async {
    final index = polls < statuses.length ? polls : statuses.length - 1;
    polls++;
    if (statuses.isEmpty) return [];
    return [_transaction(statuses[index])];
  }
}

CardRechargeService _service(
  _FakeWalletService wallet, {
  _FakeTokenizer? tokenizer,
  int maxPollAttempts = 3,
}) => CardRechargeService(
  cardTokenizer: tokenizer ?? _FakeTokenizer(),
  walletService: wallet,
  pollInterval: Duration.zero,
  maxPollAttempts: maxPollAttempts,
);

void main() {
  group('CardFormData.validate', () {
    test('accepts a complete form', () {
      expect(_data().validate(), isNull);
    });

    test('rejects an incomplete card', () {
      for (final data in [
        _data(cardNumber: '4111 1111'),
        _data(holderName: ''),
        _data(expiration: '12/3'),
        _data(cvv: '12'),
      ]) {
        expect(
          data.validate(),
          'Completa todos los campos de la tarjeta correctamente.',
        );
      }
    });

    test('requires phone and document number', () {
      expect(
        _data(phone: '').validate(),
        'Ingresa tu teléfono y documento de identidad.',
      );
      expect(
        _data(documentNumber: '').validate(),
        'Ingresa tu teléfono y documento de identidad.',
      );
    });

    test('requires accepting the terms', () {
      expect(
        _data(acceptedTerms: false).validate(),
        'Debes aceptar los Términos y Condiciones.',
      );
    });
  });

  group('CardRechargeService.recharge', () {
    test('sends the token and document data to the backend', () async {
      final wallet = _FakeWalletService(
        response: RechargeResponse(paymentUrl: 'https://pay'),
      );
      final tokenizer = _FakeTokenizer();

      final status = await _service(
        wallet,
        tokenizer: tokenizer,
      ).recharge(walletId: 7, amount: 5, data: _data());

      expect(status, CardRechargeStatus.submitted);
      expect(tokenizer.expiryMonth, '12');
      expect(tokenizer.expiryYear, '30');
      expect(wallet.sentRequest?.kushkiToken, 'tok_test');
      expect(wallet.sentRequest?.walletId, 7);
      expect(wallet.sentRequest?.documentType, 'CC');
    });

    test('is credited once the transaction succeeds', () async {
      final wallet = _FakeWalletService(
        response: RechargeResponse(),
        statuses: ['pending', 'success'],
      );

      final status = await _service(
        wallet,
      ).recharge(walletId: 7, amount: 5, data: _data());

      expect(status, CardRechargeStatus.credited);
      expect(wallet.polls, 2);
    });

    test('is rejected when the transaction fails', () async {
      final wallet = _FakeWalletService(
        response: RechargeResponse(),
        statuses: ['failed'],
      );

      final status = await _service(
        wallet,
      ).recharge(walletId: 7, amount: 5, data: _data());

      expect(status, CardRechargeStatus.rejected);
    });

    test('times out when it stays pending', () async {
      final wallet = _FakeWalletService(
        response: RechargeResponse(),
        statuses: ['pending'],
      );

      final status = await _service(
        wallet,
        maxPollAttempts: 3,
      ).recharge(walletId: 7, amount: 5, data: _data());

      expect(status, CardRechargeStatus.timedOut);
      expect(wallet.polls, 3);
    });

    test('stops polling when the screen is gone', () async {
      final wallet = _FakeWalletService(
        response: RechargeResponse(),
        statuses: ['pending'],
      );
      var calls = 0;

      final status = await _service(wallet).recharge(
        walletId: 7,
        amount: 5,
        data: _data(),
        isCancelled: () => ++calls > 1,
      );

      expect(status, CardRechargeStatus.cancelled);
      expect(wallet.polls, 0);
    });
  });
}
