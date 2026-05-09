// lib/home_page.dart
import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'settings_page.dart';
import 'file_scanner_service.dart';
import 'confirmation_page.dart';
import 'fatura_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Lida com a importação de ficheiros (PDF ou Imagem)
  Future<void> _handleFileImport(BuildContext context) async {
    final fileScanner = FileScannerService();

    // O serviço devolve:
    // - O texto do QR Code (Sucesso)
    // - 'NOT_FOUND' (Ficheiro processado, mas sem código)
    // - null (Utilizador cancelou a seleção)
    final qrData = await fileScanner.selectAndScan(context);

    if (!context.mounted) return;

    // Se o utilizador cancelou, saímos em silêncio sem mostrar SnackBar
    if (qrData == null) return;

    if (qrData == 'NOT_FOUND') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi detetado nenhum QR Code válido no ficheiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final fatura = Fatura.fromQrCodeString(qrData);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(fatura: fatura),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao interpretar os dados da fatura.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8;
    const double buttonHeight = 60.0;

    final btnStyle = ElevatedButton.styleFrom(
      fixedSize: Size(buttonWidth, buttonHeight),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Laterais curvas
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registo de despesas'),
        centerTitle: false,
        actions: [
          // Ícone único para Definições
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Definições e Gestão',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity, // Força a Column a ter onde se centrar
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(),

              const Text(
                'Selecione o método de leitura da fatura.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Botão para digitalização via câmara
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Digitalizar Fatura'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScannerPage(),
                    ),
                  );
                },
                style: btnStyle,
              ),

              const SizedBox(height: 20),

              // Botão para importação de ficheiro (PDF, JPG, PNG)
              ElevatedButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text('Importar Ficheiro (PDF/Foto)'),
                onPressed: () => _handleFileImport(context),
                style: btnStyle,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
