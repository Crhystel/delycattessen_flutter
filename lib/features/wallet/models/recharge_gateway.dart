/// Pasarelas de recarga. Cuál corresponde a cada monto lo decide el servidor.
enum RechargeGateway {
  payphone('payphone'),
  kushki('kushki');

  final String apiValue;
  const RechargeGateway(this.apiValue);

  /// null si el servidor devuelve una pasarela que esta versión no conoce.
  static RechargeGateway? fromApi(String? value) {
    for (final gateway in RechargeGateway.values) {
      if (gateway.apiValue == value) return gateway;
    }
    return null;
  }
}
