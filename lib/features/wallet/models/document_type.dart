enum DocumentType { cedula, ruc, pasaporte }

extension DocumentTypeLabel on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.cedula:
        return 'Cédula de identidad';
      case DocumentType.ruc:
        return 'RUC';
      case DocumentType.pasaporte:
        return 'Pasaporte';
    }
  }

  String get apiCode {
    switch (this) {
      case DocumentType.cedula:
        return 'CC';
      case DocumentType.ruc:
        return 'RUC';
      case DocumentType.pasaporte:
        return 'PPT';
    }
  }
}
