// lib/fatura_model.dart

class Fatura {
  // Chave A: NIF do emitente / comerciante
  final String nifComerciante;

  // Chave B: NIF do adquirente / cliente (opcional)
  final String nifCliente;

  // Chave C: País do adquirente / cliente (opcional)
  final String paisCliente;

  // Chave D: Tipo de documento (ex: FT - Fatura, FS - Fatura Simplificada)
  final String tipoDocumento;

  // Chave E: Estado do documento (ex: N - Normal, C - Cancelado)
  final String estadoDocumento;

  // Chave F: Data de emissão do documento
  final DateTime data;

  // Chave G: Identificação única do documento (Série e Número da fatura)
  final String identificacaoDocumento;

  // Chave H: ATCUD (Código único do documento)
  final String atcud;

  // Chave O: Valor total do documento (com impostos)
  final double valorTotal;

  // Chave N: Valor total do IVA
  final double valorIva;

  // Chave S: Informação de controlo (depende do terminal)
  final String informacaoControlo;

  Fatura({
    required this.nifComerciante,
    required this.nifCliente,
    required this.paisCliente,
    required this.tipoDocumento,
    required this.estadoDocumento,
    required this.data,
    required this.identificacaoDocumento,
    required this.atcud,
    required this.valorTotal,
    required this.valorIva,
    required this.informacaoControlo,
  });

  // Método copyWith mantém-se limpo, focado em atualizar o DateTime composto
  Fatura copyWith({DateTime? data}) {
    return Fatura(
      nifComerciante: nifComerciante,
      nifCliente: nifCliente,
      paisCliente: paisCliente,
      tipoDocumento: tipoDocumento,
      estadoDocumento: estadoDocumento,
      data: data ?? this.data,
      identificacaoDocumento: identificacaoDocumento,
      atcud: atcud,
      valorTotal: valorTotal,
      valorIva: valorIva,
      informacaoControlo: informacaoControlo,
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

    final String nif = dataMap['A'] ?? 'N/A';
    final String nifCliente = dataMap['B'] ?? 'N/A';
    final String paisCliente = dataMap['C'] ?? 'N/A';
    final String tipoDoc = dataMap['D'] ?? 'Fatura';
    final String numDoc = dataMap['E'] ?? 'N/A';

    final String dataString = dataMap['F'] ?? ''; // Formato: 20250924
    final DateTime dateNow = DateTime.now();
    DateTime dataFatura = dateNow;

    final DateTime? dataParse = DateTime.tryParse(dataString);
    if (dataParse != null) {
      // Fusão da data obtida via tryParse com a hora e minuto atuais do sistema
      dataFatura = DateTime(
        dataParse.year,
        dataParse.month,
        dataParse.day,
        dateNow.hour,
        dateNow.minute,
      );
    }

    final String identificacaoDoc = dataMap['G'] ?? '';
    final String atcudCode = dataMap['H'] ?? '';
    final double valorIva = double.tryParse(dataMap['N'] ?? '0.0') ?? 0.0;
    final double valorTotal = double.tryParse(dataMap['O'] ?? '0.0') ?? 0.0;
    final String informacaoControlo = dataMap['S'] ?? '';

    return Fatura(
      nifComerciante: nif,
      nifCliente: nifCliente,
      paisCliente: paisCliente,
      tipoDocumento: tipoDoc,
      estadoDocumento: numDoc,
      data: dataFatura,
      identificacaoDocumento: identificacaoDoc,
      valorTotal: valorTotal,
      valorIva: valorIva,
      atcud: atcudCode,
      informacaoControlo: informacaoControlo,
    );
  }

  @override
  String toString() {
    final horaTexto =
        "${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
    final dataFormatada =
        "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} $horaTexto";

    return 'NIF: $nifComerciante\n'
        'Data: $dataFormatada\n'
        'Tipo: $tipoDocumento\n'
        'Doc: $identificacaoDocumento\n'
        'ATCUD: $atcud\n'
        'Valor: ${valorTotal.toStringAsFixed(2)}€ (IVA: ${valorIva.toStringAsFixed(2)}€)\n'
        '${informacaoControlo.isNotEmpty ? "Controlo: $informacaoControlo" : ""}';
  }
}
