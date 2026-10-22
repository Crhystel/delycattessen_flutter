/// Convierte los datos de una tarjeta en un token de un solo uso. La pantalla
/// de recarga depende de esta abstracción y no de una pasarela concreta, así
/// se puede cambiar de proveedor o simularla en tests.
abstract class CardTokenizer {
  Future<String> tokenizeCard({
    required String cardNumber,
    required String cvv,
    required String expiryMonth,
    required String expiryYear,
    required String holderName,
    required double amount,
  });
}
