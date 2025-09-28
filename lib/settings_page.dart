// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'management_page.dart';
import 'category_editor_page.dart';
import 'backup_service.dart';
import 'about_page.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BackupService _backupService = BackupService();
  final SettingsService _settingsService = SettingsService();
  bool _isProcessing = false;

  bool _confirmOnCashew = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Carregar definições ---
  Future<void> _loadSettings() async {
    final confirmValue = await _settingsService.getConfirmOnCashew();
    if (mounted) {
      setState(() {
        _confirmOnCashew = confirmValue;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
    });
    String message = 'Exportação iniciada...'; // Mensagem padrão
    try {
      await _backupService.exportData();
      // A mensagem de sucesso é implícita pela ação de partilha
      return;
    } catch (e) {
      message = e.toString();
    } finally {
      // Verificar se o widget ainda está montado
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      // Apenas mostra o snackbar em caso de erro
      if (message != 'Exportação iniciada...') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isProcessing = true;
    });
    String message = '';
    try {
      message = await _backupService.importData();
    } catch (e) {
      message = e.toString();
    } finally {
      // Verificar se o widget ainda está montado
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definições e Gestão')),
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
                    setState(() {
                      _confirmOnCashew = value;
                    });
                  },
                  secondary: const Icon(Icons.touch_app),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Gerir Categorias'),
                  subtitle: const Text(
                    'Adicionar, editar ou apagar categorias',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => const CategoryEditorPage(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Gerir Comerciantes'),
                  subtitle: const Text('Ver e editar os NIFs guardados'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ManagementPage()),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Exportar Dados (Backup)'),
                  subtitle: const Text(
                    'Guarda todas as categorias e comerciantes num ficheiro',
                  ),
                  onTap: _handleExport,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Importar Dados (Restauro)'),
                  subtitle: const Text(
                    'Carrega os dados a partir de um ficheiro de backup',
                  ),
                  onTap: _handleImport,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre a Aplicação'),
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
