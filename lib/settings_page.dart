// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'management_page.dart';
import 'category_editor_page.dart';
import 'about_page.dart';
import 'settings_service.dart';
import 'account_editor_page.dart';
import 'import_export_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    // Garante que o último item pode ser rolado para fora da
                    // barra de navegação do sistema e fica totalmente visível.
                    padding: EdgeInsets.only(
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
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
                          MaterialPageRoute(
                            builder: (c) => const ManagementPage(),
                          ),
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
                        leading: const Icon(Icons.import_export),
                        title: const Text('Importar / Exportar'),
                        subtitle: const Text(
                          'Backup dos dados da aplicação e importação do Cashew',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => const ImportExportPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // "Sobre CajuScan" fica sempre visível, sem depender de scroll.
                SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1),
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
                ),
              ],
            ),
    );
  }
}
