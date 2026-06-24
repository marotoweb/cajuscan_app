// lib/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'fatura_model.dart';
import 'profile_service.dart';
import 'cashew_launcher.dart';
import 'merchant_profile.dart';
import 'settings_service.dart';

class ConfirmationPage extends StatefulWidget {
  final Fatura fatura;
  final Map<String, List<String>> categories;
  final List<String> accounts;

  const ConfirmationPage({
    super.key,
    required this.fatura,
    required this.categories,
    required this.accounts,
  });

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final ProfileService _profileService = ProfileService();
  final CashewLauncher _cashewLauncher = CashewLauncher();
  final SettingsService _settingsService = SettingsService();

  MerchantProfile? _profile;
  Map<String, List<String>> _allCategories = {};
  List<String> _allAccounts = [];
  String? _selectedAccount;
  String? _suggestedAccount;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isMerchantStored = false;
  bool _sendFiscalInfo = false;

  late Fatura _localFatura;

  // Chaves para persistência do histórico de predição
  static const String _globalHistoryKey = 'ac_global_history';
  static const String _merchantHistoryKey = 'ac_merchant_history';

  @override
  void initState() {
    super.initState();
    _localFatura = widget.fatura;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loadedProfile = await _profileService.getProfile(
        _localFatura.merchantNif,
      );

      final loadedCategories = widget.categories;
      final loadedAccounts = widget.accounts;
      final sendFiscalValue = await _settingsService.getSendFiscalInfo();

      final prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _allCategories = loadedCategories;
          _isMerchantStored = loadedProfile != null;
          _sendFiscalInfo = sendFiscalValue;

          _profile =
              loadedProfile ??
              MerchantProfile(name: 'Desconhecido', category: '');

          List<String> accounts = List<String>.from(loadedAccounts);
          final String globalRaw = prefs.getString(_globalHistoryKey) ?? '{}';
          final String merchantRaw =
              prefs.getString(_merchantHistoryKey) ?? '{}';

          final Map<String, dynamic> globalHistory = json.decode(globalRaw);
          final Map<String, dynamic> merchantHistory = json.decode(merchantRaw);

          final String merchantId = _localFatura.merchantNif;
          final Map<String, dynamic> thisMerchantHistory =
              merchantHistory[merchantId] ?? {};

          String? prediction;

          // Regra 1: Mais utilizada para este comerciante específico
          if (thisMerchantHistory.isNotEmpty) {
            prediction = thisMerchantHistory.entries
                .reduce((a, b) => (a.value as int) > (b.value as int) ? a : b)
                .key;
          }

          if ((prediction == null || !accounts.contains(prediction)) &&
              globalHistory.isNotEmpty) {
            prediction = globalHistory.entries
                .reduce((a, b) => (a.value as int) > (b.value as int) ? a : b)
                .key;
          }

          // Regra 3: Primeira da lista (Fallback final)
          if (prediction == null || !accounts.contains(prediction)) {
            prediction = accounts.isNotEmpty ? accounts.first : null;
          }

          // Ordenação da lista: coloca as mais usadas globalmente no topo
          accounts.sort((a, b) {
            final int countA = globalHistory[a] ?? 0;
            final int countB = globalHistory[b] ?? 0;
            return countB.compareTo(countA);
          });

          _allAccounts = accounts;
          _suggestedAccount = prediction;
          _selectedAccount = prediction;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Regista a utilização da conta para refinar as futuras sugestões
  Future<void> _incrementAccountUsage(String account) async {
    final prefs = await SharedPreferences.getInstance();
    final String merchantId = _localFatura.merchantNif;

    // Atualiza o histórico global
    final String globalRaw = prefs.getString(_globalHistoryKey) ?? '{}';
    final Map<String, dynamic> globalHistory = Map<String, dynamic>.from(
      json.decode(globalRaw),
    );
    globalHistory[account] = (globalHistory[account] ?? 0) + 1;
    await prefs.setString(_globalHistoryKey, json.encode(globalHistory));

    // Atualiza o histórico por comerciante
    final String merchantRaw = prefs.getString(_merchantHistoryKey) ?? '{}';
    final Map<String, dynamic> merchantHistory = Map<String, dynamic>.from(
      json.decode(merchantRaw),
    );

    final Map<String, dynamic> thisMerchantHistory =
        merchantHistory.containsKey(merchantId) &&
            merchantHistory[merchantId] is Map
        ? Map<String, dynamic>.from(merchantHistory[merchantId] as Map)
        : {};

    thisMerchantHistory[account] = (thisMerchantHistory[account] ?? 0) + 1;
    merchantHistory[merchantId] = thisMerchantHistory;

    await prefs.setString(_merchantHistoryKey, json.encode(merchantHistory));
  }

  /// Despoleta a janela nativa para alteração da componente temporal
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(_localFatura.date);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && picked != currentTime) {
      setState(() {
        _localFatura = _localFatura.copyWith(
          date: DateTime(
            _localFatura.date.year,
            _localFatura.date.month,
            _localFatura.date.day,
            picked.hour,
            picked.minute,
          ),
        );
      });
    }
  }

  // --- Regista no Cashew e guarda o perfil ---
  Future<void> _registerTransaction() async {
    if (_profile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Guarda a utilização da conta para inteligência futura antes de lançar o Cashew
      if (_selectedAccount != null) {
        await _incrementAccountUsage(_selectedAccount!);
      }

      // Guarda o perfil atualizado
      await _profileService.saveProfile(_localFatura.merchantNif, _profile!);

      // Enviamos apenas a fatura local totalmente atualizada
      await _cashewLauncher.launchCashew(
        fatura: _localFatura,
        category: _profile!.category,
        subcategory: _profile!.subcategory,
        account: _selectedAccount,
        title: _profile!.name,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveProfileOnly() async {
    if (_profile == null) return;

    // Validar se o utilizador está a tentar guardar com o nome padrão "Desconhecido"
    if (_profile!.name.trim() == 'Desconhecido' ||
        _profile!.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, defina o nome do comerciante antes de guardar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    try {
      await _profileService.saveProfile(_localFatura.merchantNif, _profile!);
      if (mounted) {
        setState(() {
          _isMerchantStored = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comerciante "${_profile!.name}" guardado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Abre diálogo simples e focado para editar apenas o nome do comerciante
  void _showEditMerchantNameDialog() {
    if (_profile == null) return;

    final localNameController = TextEditingController(
      text: _profile!.name == 'Desconhecido' ? '' : _profile!.name,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome do comerciante'),
          content: TextField(
            controller: localNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do estabelecimento',
              hintText: 'Ex: Continente, Pingo Doce',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (localNameController.text.trim().isNotEmpty) {
                  setState(() {
                    _profile = MerchantProfile(
                      name: localNameController.text.trim(),
                      category: _profile!.category,
                      subcategory: _profile!.subcategory,
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  /// Desenrola o painel inferior para seleção rápida da categoria e subcategoria
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Text(
                        'Selecionar categoria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: _allCategories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'Nenhuma categoria disponível. Configure no Cashew.',
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              shrinkWrap: true,
                              itemCount: _allCategories.keys.length,
                              itemBuilder: (context, index) {
                                final category = _allCategories.keys.elementAt(
                                  index,
                                );
                                final subcategories =
                                    _allCategories[category] ?? [];
                                final isSelectedCategory =
                                    _profile?.category == category;

                                if (subcategories.isEmpty) {
                                  return ListTile(
                                    leading: Icon(
                                      Icons.category_outlined,
                                      color: isSelectedCategory
                                          ? Colors.green
                                          : Colors.blueGrey,
                                    ),
                                    title: Text(
                                      category,
                                      style: TextStyle(
                                        fontWeight: isSelectedCategory
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelectedCategory
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _profile = MerchantProfile(
                                          name:
                                              _profile?.name ?? 'Desconhecido',
                                          category: category,
                                          subcategory: null,
                                        );
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }

                                return ExpansionTile(
                                  leading: Icon(
                                    Icons.category,
                                    color: isSelectedCategory
                                        ? Colors.green
                                        : Colors.blueGrey,
                                  ),
                                  title: Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: isSelectedCategory
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  initiallyExpanded: isSelectedCategory,
                                  children: subcategories.map((sub) {
                                    final isSelectedSub =
                                        isSelectedCategory &&
                                        _profile?.subcategory == sub;
                                    return ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        56,
                                        0,
                                        20,
                                        0,
                                      ),
                                      leading: Icon(
                                        Icons.subdirectory_arrow_right,
                                        size: 18,
                                        color: isSelectedSub
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      title: Text(
                                        sub,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isSelectedSub
                                              ? Colors.green
                                              : null,
                                          fontWeight: isSelectedSub
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: isSelectedSub
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 18,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _profile = MerchantProfile(
                                            name:
                                                _profile?.name ??
                                                'Desconhecido',
                                            category: category,
                                            subcategory: sub,
                                          );
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Desenrola o painel inferior para seleção rápida da conta
  void _showAccountBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Selecionar conta de destino',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: _allAccounts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Nenhuma conta disponível. Configure no Cashew.',
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _allAccounts.length,
                          itemBuilder: (context, index) {
                            final account = _allAccounts[index];
                            final isSuggested = account == _suggestedAccount;
                            final isSelected = account == _selectedAccount;

                            return ListTile(
                              leading: Icon(
                                isSuggested
                                    ? Icons.stars
                                    : Icons.account_balance_wallet,
                                color: isSuggested
                                    ? Colors.amber[700]
                                    : Colors.blueGrey,
                              ),
                              title: Text(
                                account,
                                style: TextStyle(
                                  fontWeight: isSuggested || isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : (isSuggested
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Sugerida',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          )
                                        : null),
                              onTap: () {
                                setState(() {
                                  _selectedAccount = account;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    if (_profile == null) return;

    final localNameController = TextEditingController(text: _profile!.name);

    String? dialogSelectedCategory = _profile!.category.isEmpty
        ? null
        : _profile!.category;
    String? dialogSelectedSubcategory = _profile!.subcategory;
    String? dialogSelectedAccount = _selectedAccount;

    if (dialogSelectedCategory != null &&
        !_allCategories.containsKey(dialogSelectedCategory)) {
      dialogSelectedCategory = null;
      dialogSelectedSubcategory = null;
    }
    if (dialogSelectedSubcategory != null &&
        !(_allCategories[dialogSelectedCategory]?.contains(
              dialogSelectedSubcategory,
            ) ??
            false)) {
      dialogSelectedSubcategory = null;
    }
    if (dialogSelectedAccount != null &&
        !_allAccounts.contains(dialogSelectedAccount)) {
      dialogSelectedAccount = _allAccounts.isNotEmpty
          ? _allAccounts.first
          : null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableSubcategories =
                _allCategories[dialogSelectedCategory] ?? [];

            return AlertDialog(
              title: const Text('Editar comerciante'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: localNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do comerciante',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: dialogSelectedCategory,
                      hint: const Text('Nenhuma (Selecionar no Cashew)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma (Selecionar no Cashew)'),
                        ),
                        ..._allCategories.keys.map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                      onChanged: (newValue) {
                        setDialogState(() {
                          dialogSelectedCategory = newValue;
                          dialogSelectedSubcategory = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 20),
                    if (dialogSelectedCategory != null &&
                        availableSubcategories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: dialogSelectedSubcategory,
                        hint: const Text('Nenhuma'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Nenhuma'),
                          ),
                          ...availableSubcategories.map(
                            (sub) =>
                                DropdownMenuItem(value: sub, child: Text(sub)),
                          ),
                        ],
                        onChanged: (newValue) {
                          setDialogState(() {
                            dialogSelectedSubcategory = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Subcategoria',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: dialogSelectedAccount,
                      hint: const Text('Nenhuma (Selecionar no Cashew)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma (Selecionar no Cashew)'),
                        ),
                        ..._allAccounts.map(
                          (acc) =>
                              DropdownMenuItem(value: acc, child: Text(acc)),
                        ),
                      ],
                      onChanged: (newValue) {
                        setDialogState(() {
                          dialogSelectedAccount = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Conta de destino',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (localNameController.text.isNotEmpty) {
                      setState(() {
                        _profile = MerchantProfile(
                          name: localNameController.text,
                          category: dialogSelectedCategory ?? '',
                          subcategory: dialogSelectedSubcategory,
                        );
                        _selectedAccount = dialogSelectedAccount;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Confirmar alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dataTexto =
        "${_localFatura.date.day.toString().padLeft(2, '0')}/${_localFatura.date.month.toString().padLeft(2, '0')}/${_localFatura.date.year}";

    final String horaTexto =
        "${_localFatura.date.hour.toString().padLeft(2, '0')}:${_localFatura.date.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar despesa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar perfil',
            onPressed: _isLoading ? null : _showEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: InkWell(
                      onTap: _isLoading ? null : _showEditMerchantNameDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.store, size: 40),
                        title: Text(
                          _profile?.name ?? 'Carregando...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('NIF: ${_localFatura.merchantNif}'),
                        trailing: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month, size: 40),
                        title: const Text('Data e hora da fatura'),
                        subtitle: Text(
                          '$dataTexto às $horaTexto',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: _isLoading ? null : _showCategoryBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.category, size: 40),
                        title: const Text('Categoria'),
                        subtitle: Text(
                          _profile?.category.isEmpty ?? true
                              ? 'Não definida'
                              : '${_profile!.category}${_profile!.subcategory != null ? ' > ${_profile!.subcategory}' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: _showAccountBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          size: 40,
                        ),
                        title: const Text('Conta de destino'),
                        subtitle: Text(
                          _selectedAccount ??
                              'Não definida (Selecionar no Cashew)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.euro, size: 40),
                      title: const Text('Valor total'),
                      subtitle: Text(
                        '${_localFatura.totalAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_sendFiscalInfo) ...[
                    Card(
                      color: Colors.yellow[100],
                      child: ListTile(
                        leading: const Icon(Icons.info, size: 40),
                        title: const Text('Notas adicionais'),
                        subtitle: Text(
                          _localFatura.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Espaço flexível para empurrar o botão para baixo
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Registar no Cashew',
                              style: TextStyle(fontSize: 18),
                            ),
                      onPressed: _isProcessing ? null : _registerTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  // Botão para guardar apenas o comerciante, se ainda não estiver guardado
                  if (!_isMerchantStored) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Apenas guardar comerciante',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: _isProcessing ? null : _saveProfileOnly,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Espaço extra para evitar que o botão fique muito próximo da parte inferior da tela
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 12.0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
