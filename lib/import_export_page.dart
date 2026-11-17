// lib/import_export_page.dart
import 'package:flutter/material.dart';
import 'account_management_service.dart';
import 'backup_service.dart';
import 'cashew_import_service.dart';
import 'category_management_service.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  final BackupService _backupService = BackupService();
  final CashewImportService _cashewImportService = CashewImportService();
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  final AccountManagementService _accountService = AccountManagementService();
  bool _isProcessing = false;

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
    });

    String statusMessage = '';
    bool isError = false;

    try {
      final bool success = await _backupService.exportData();
      if (success) {
        statusMessage = 'Exportação concluída com sucesso!';
      }
    } catch (e) {
      statusMessage = e.toString().replaceAll('Exception: ', '');
      isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }

    if (statusMessage.isNotEmpty && mounted) {
      _showSnackBar(statusMessage, isError ? Colors.red : Colors.green);
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isProcessing = true;
    });

    String statusMessage = '';
    bool isError = false;

    try {
      final bool success = await _backupService.importData();
      if (success) {
        statusMessage = 'Dados importados com sucesso!';
      }
    } catch (e) {
      statusMessage = e.toString().replaceAll('Exception: ', '');
      isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }

    if (statusMessage.isNotEmpty && mounted) {
      _showSnackBar(statusMessage, isError ? Colors.red : Colors.green);
    }
  }

  Future<void> _handleCashewImport() async {
    setState(() {
      _isProcessing = true;
    });

    final result = await _cashewImportService.pickAndParse();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    // Utilizador cancelou o diálogo de ficheiros
    if (result.errorMessage == 'cancelled' ||
        result.errorMessage == 'Nenhum ficheiro selecionado.') {
      return;
    }

    if (!result.success) {
      if (mounted) {
        _showSnackBar(result.errorMessage!, Colors.red);
      }
      return;
    }

    final categories = result.categories;
    final accounts = result.accounts;

    final hasCategories = categories != null && categories.isNotEmpty;
    final hasAccounts = accounts != null && accounts.isNotEmpty;

    if (!hasCategories && !hasAccounts) {
      if (mounted) {
        _showSnackBar(
          'O ficheiro não contém dados válidos para importação.',
          Colors.red,
        );
      }
      return;
    }

    if (!mounted) return;

    // Construção da mensagem informativa do diálogo
    final List<String> infoLines = [];
    if (hasCategories) {
      infoLines.add('Foram encontradas ${categories.length} categorias.');
    }
    if (hasAccounts) {
      infoLines.add('Foram encontradas ${accounts.length} contas.');
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar dados do Cashew'),
        content: Text(
          '${infoLines.join('\n')}\n\n'
          'Isto irá substituir as configurações atuais na aplicação. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final List<String> successMessages = [];

      if (hasCategories) {
        await _categoryService.saveCategories(categories);
        successMessages.add('${categories.length} categorias');
      }

      if (hasAccounts) {
        await _accountService.saveAccounts(accounts);
        successMessages.add('${accounts.length} contas');
      }

      if (mounted) {
        _showSnackBar(
          'Dados importados com sucesso: ${successMessages.join(' e ')}.',
          Colors.green,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Erro ao guardar os dados do Cashew.', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar / Exportar')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Exportar dados (Backup)'),
                  subtitle: const Text(
                    'Guarda todas os dados da aplicação num ficheiro',
                  ),
                  onTap: _handleExport,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Importar dados (Restauro)'),
                  subtitle: const Text(
                    'Carrega os dados a partir de um ficheiro de backup',
                  ),
                  onTap: _handleImport,
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Importar dados do Cashew'),
                  subtitle: const Text(
                    'Carrega categorias e contas a partir de uma exportação do Cashew',
                  ),
                  onTap: _handleCashewImport,
                ),
              ],
            ),
    );
  }
}
