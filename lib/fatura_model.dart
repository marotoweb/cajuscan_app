// lib/fatura_model.dart

class Fatura {
  // Chave A: NIF do emitente / comerciante
  // Exemplo: A:123456789
  final String merchantNif;

  // Chave B: NIF do adquirente / cliente (opcional)
  // Exemplo: B:999999990
  final String clientNif;

  // Chave C: País do adquirente / cliente (opcional)
  // Exemplo: C:PT
  final String clientCountry;

  // Chave D: Tipo de documento (ex: FT - Fatura, FS - Fatura Simplificada)
  // Exemplo: D:FT
  final String documentType;

  // Chave E: Estado do documento (ex: N - Normal, C - Cancelado)
  // Exemplo: E:N
  final String documentStatus;

  // Chave F: Data de emissão do documento
  //Exemplo: F:20191231
  final DateTime date;

  // Chave G: Identificação única do documento
  // Exemplo: G:FT AB2019/0035
  final String documentId;

  // Chave H: ATCUD (Código único do documento)
  // Exemplo: H:CSDF7T5H0035
  final String atcud;

  // Chave N: Valor total de IVA e Imposto do Selo
  // N:64000.02
  final double vatAmount;

  // Chave O: Valor total do documento com impostos
  // Exemplo: O:513600.58
  final double totalAmount;

  // Chave Q: 4 carateres do Hash
  // Exemplo: Q:kLp0
  final String docHash;

  // Chave S: Outras informações
  final String controlInfo;

  Fatura({
    required this.merchantNif,
    required this.clientNif,
    required this.clientCountry,
    required this.documentType,
    required this.documentStatus,
    required this.date,
    required this.documentId,
    required this.atcud,
    required this.vatAmount,
    required this.totalAmount,
    required this.docHash,
    required this.controlInfo,
  });

  // Método copyWith mantém-se limpo, focado em atualizar o DateTime composto
  Fatura copyWith({DateTime? date}) {
    return Fatura(
      merchantNif: merchantNif,
      clientNif: clientNif,
      clientCountry: clientCountry,
      documentType: documentType,
      documentStatus: documentStatus,
      date: date ?? this.date,
      documentId: documentId,
      atcud: atcud,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      docHash: docHash,
      controlInfo: controlInfo,
    );
  }

  // Método para criar uma instância de Fatura a partir de uma string de código QR
  factory Fatura.fromQrCodeString(String qrCode) {
    final Map<String, String> dataMap = {};

    // O QR Code da AT separa os campos por '*'
    final parts = qrCode.split('*');
    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length >= 2) {
        // Usa o primeiro elemento como chave e junta o resto (caso o valor contenha ':')
        dataMap[keyValue[0]] = keyValue.sublist(1).join(':');
      }
    }

    final String merchantNif = dataMap['A'] ?? 'N/A';
    final String clientNif = dataMap['B'] ?? 'N/A';
    final String clientCountry = dataMap['C'] ?? 'N/A';
    final String documentType = dataMap['D'] ?? 'Fatura';
    final String documentStatus = dataMap['E'] ?? 'N/A';

    final String rawDate = (dataMap['F'] ?? '').trim();
    final DateTime dateNow = DateTime.now();
    DateTime finalDate = dateNow;

    if (rawDate.length == 8) {
      final String year = rawDate.substring(0, 4);
      final String month = rawDate.substring(4, 6);
      final String day = rawDate.substring(6, 8);

      // Reconstrói no formato ISO (AAAA-MM-DD) aceitado nativamente pelo tryParse
      final DateTime? parsedDate = DateTime.tryParse('$year-$month-$day');
      if (parsedDate != null) {
        finalDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          dateNow.hour,
          dateNow.minute,
        );
      }
    }

    final String documentId = dataMap['G'] ?? '';
    final String atcud = dataMap['H'] ?? '';

    final double vatAmount =
        double.tryParse((dataMap['N'] ?? '0.0').trim()) ?? 0.0;
    final double totalAmount =
        double.tryParse((dataMap['O'] ?? '0.0').trim()) ?? 0.0;

    final String docHash = dataMap['Q'] ?? '';
    final String controlInfo = dataMap['S'] ?? '';

    return Fatura(
      merchantNif: merchantNif,
      clientNif: clientNif,
      clientCountry: clientCountry,
      documentType: documentType,
      documentStatus: documentStatus,
      date: finalDate,
      documentId: documentId,
      atcud: atcud,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      docHash: docHash,
      controlInfo: controlInfo,
    );
  }

  @override
  String toString() {
    return 'NIF: $merchantNif\n'
        'Tipo: $documentType\n'
        'Doc: $documentId\n'
        'ATCUD: $atcud\n'
        'Valor: ${totalAmount.toStringAsFixed(2)}€ (IVA: ${vatAmount.toStringAsFixed(2)}€)\n'
        'Hash: $docHash\n'
        '${controlInfo.isNotEmpty ? "Controlo: $controlInfo" : ""}';
  }
}
