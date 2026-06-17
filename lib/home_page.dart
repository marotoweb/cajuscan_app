// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'scanner_page.dart';
import 'settings_page.dart';
import 'file_scanner_service.dart';
import 'confirmation_page.dart';
import 'fatura_model.dart';
import 'category_management_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  late StreamSubscription _intentSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentSubscription.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // App aberta através de um share enquanto já estava em background
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedContent(files.first);
        }
      },
    );

    // App lançada directamente pelo share (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> files,
    ) {
      if (files.isNotEmpty) {
        _handleSharedContent(files.first);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  Future<void> _handleSharedContent(SharedMediaFile file) async {
    String? jsonString;

    if (file.type == SharedMediaType.text) {
      jsonString = file.path;
    } else if (file.type == SharedMediaType.file) {
      try {
        final f = await _readFile(file.path);
        jsonString = f;
      } catch (_) {
        _showError('Não foi possível ler o ficheiro partilhado.');
        return;
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      _showError('Conteúdo partilhado vazio ou inválido.');
      return;
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      _showError('O conteúdo partilhado não é um JSON válido.');
      return;
    }

    // Verifica se o JSON contém alguma das chaves esperadas do Cashew
    if (!data.containsKey('categories') && !data.containsKey('accounts')) {
      return;
    }

    // 1. Processar Categorias
    Map<String, List<String>> categories = {};
    if (data.containsKey('categories') && data['categories'] is Map) {
      final rawCategories = data['categories'] as Map<String, dynamic>;
      categories = rawCategories.map((key, value) {
        final subs = (value as List<dynamic>).whereType<String>().toList();
        return MapEntry(key, subs);
      });
    }

    // 2. Processar Contas
    Map<String, dynamic> accounts = {};
    if (data.containsKey('accounts') && data['accounts'] is Map) {
      accounts = data['accounts'] as Map<String, dynamic>;
    }

    if (categories.isEmpty && accounts.isEmpty) {
      _showError('O ficheiro não contém categorias nem contas válidas.');
      return;
    }

    if (!mounted) return;
    _showImportDialog(categories, accounts);
  }

  Future<String> _readFile(String path) async {
    return File(path).readAsString();
  }

  void _showImportDialog(
    Map<String, List<String>> categories,
    Map<String, dynamic> accounts,
  ) {
    // Constrói a mensagem informativa do diálogo baseada no que foi encontrado
    final List<String> infoLines = [];
    if (categories.isNotEmpty) infoLines.add('${categories.length} categorias');
    if (accounts.isNotEmpty) infoLines.add('${accounts.length} contas');
    final String contentMessage = infoLines.join(' e ');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar dados do Cashew'),
        content: Text(
          'Foram encontradas $contentMessage.\n\n'
          'Isto vai substituir os dados atuais pelos novos. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Alinha a persistência com o método unificado do teu serviço
              await _categoryService.saveCategoriesAndAccounts(
                categories: categories,
                accounts: accounts,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados importados com sucesso.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Substituir'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleFileImport(BuildContext context) async {
    final fileScanner = FileScannerService();
    final qrData = await fileScanner.selectAndScan(context);

    if (!context.mounted) return;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registo de despesas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Definições e gestão',
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
          width: double.infinity,
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
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Digitalizar fatura'),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text('Importar ficheiro (PDF/Foto)'),
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
