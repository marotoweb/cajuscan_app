// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'management_page.dart';
import 'category_editor_page.dart';
import 'backup_service.dart';
import 'about_page.dart';
import 'settings_service.dart';
import 'cashew_import_service.dart';
import 'category_management_service.dart';
import 'account_editor_page.dart';
import 'account_management_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BackupService _backupService = BackupService();
  final SettingsService _settingsService = SettingsService();
  final CashewImportService _cashewImportService = CashewImportService();
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  final AccountManagementService _accountService = AccountManagementService();
  bool _isProcessing = false;

  bool _confirmOnCashew = true;
  bool _continuousScan = true;
  bool _sendFiscalInfo = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Carregar definições ---
  Future<void> _loadSettings() async {
    final confirmValue = await _settingsService.getConfirmOnCashew();
    final continuousValue = await _settingsService.getContinuousScan();
    final fiscalInfoValue = await _settingsService.getSendFiscalInfo();
    if (mounted) {
      setState(() {
        _confirmOnCashew = confirmValue;
        _continuousScan = continuousValue;
        _sendFiscalInfo = fiscalInfoValue;
        _isLoadingSettings = false;
      });
    }
  }

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
      appBar: AppBar(title: const Text('Definições')),
      body: _isProcessing || _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // --- Interruptor de definições ---
                SwitchListTile(
                  title: const Text('Confirmar no Cashew'),
                  subtitle: const Text(
                    'Se ativo, os dados serão abertos no Cashew para confirmação antes de serem guardados.',
                  ),
                  value: _confirmOnCashew,
                  onChanged: (bool value) async {
                    await _settingsService.setConfirmOnCashew(value);
                    if (mounted) {
                      setState(() {
                        _confirmOnCashew = value;
                      });
                    }
                  },
                  secondary: const Icon(Icons.touch_app),
                ),
                SwitchListTile(
                  title: const Text('Scan contínuo'),
                  subtitle: const Text(
                    'Permite ler várias faturas sem sair da câmara.',
                  ),
                  value: _continuousScan,
                  onChanged: (bool value) async {
                    await _settingsService.setContinuousScan(value);
                    if (mounted) setState(() => _continuousScan = value);
                  },
                  secondary: const Icon(Icons.all_inclusive),
                ),
                SwitchListTile(
                  title: const Text('Anexar metadados fiscais'),
                  subtitle: const Text(
                    'Insere dados adicionais às notas da transação.',
                  ),
                  value: _sendFiscalInfo,
                  onChanged: (bool value) async {
                    await _settingsService.setSendFiscalInfo(value);
                    if (mounted) setState(() => _sendFiscalInfo = value);
                  },
                  secondary: const Icon(Icons.receipt_long),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Gerir comerciantes'),
                  subtitle: const Text(
                    'Ver e editar perfil de comerciantes guardados',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ManagementPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Gerir categorias'),
                  subtitle: const Text(
                    'Adicionar, editar ou eliminar categorias e subcategorias do Cashew',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => const CategoryEditorPage(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Gerir contas'),
                  subtitle: const Text(
                    'Adicionar, editar ou eliminar contas de destino do Cashew',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => const AccountEditorPage(),
                    ),
                  ),
                ),
                const Divider(),
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
                  onTap: _isProcessing ? null : _handleCashewImport,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre CajuScan'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
