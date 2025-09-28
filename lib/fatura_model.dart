// lib/fatura_model.dart

class Fatura {
  final String nifComerciante;
  final DateTime data;
  final double valorTotal;
  final double valorIva;
  // Adicione outros campos que queira usar no futuro
  // final String nifAdquirente;
  // final String pais;

  Fatura({
    required this.nifComerciante,
    required this.data,
    required this.valorTotal,
    required this.valorIva,
  });

  // Um "construtor de fábrica" para criar uma Fatura a partir da string do QR code
  factory Fatura.fromQrCodeString(String qrCode) {
    final Map<String, String> dataMap = {};
    final parts = qrCode.split('*');
    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        dataMap[keyValue[0]] = keyValue[1];
      }
    }

    // Extrair e converter os dados
    final String nif = dataMap['A'] ?? 'N/A';
    final String dataString = dataMap['F'] ?? ''; // Formato: 20250924
    final DateTime data = DateTime.tryParse(dataString) ?? DateTime.now();
    final double valorTotal = double.tryParse(dataMap['O'] ?? '0.0') ?? 0.0;
    final double valorIva = double.tryParse(dataMap['N'] ?? '0.0') ?? 0.0;

    return Fatura(
      nifComerciante: nif,
      data: data,
      valorTotal: valorTotal,
      valorIva: valorIva,
    );
  }

  @override
  String toString() {
    return 'NIF: $nifComerciante\nData: ${data.toLocal().toString().split(' ')[0]}\nValor: ${valorTotal.toStringAsFixed(2)}€';
  }
}
