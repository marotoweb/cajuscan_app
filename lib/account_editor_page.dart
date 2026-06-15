// lib/account_editor_page.dart

import 'package:flutter/material.dart';
import 'account_management_service.dart';

class AccountEditorPage extends StatefulWidget {
  const AccountEditorPage({super.key});

  @override
  State<AccountEditorPage> createState() => _AccountEditorPageState();
}

class _AccountEditorPageState extends State<AccountEditorPage> {
  final AccountManagementService _accountService = AccountManagementService();
  List<String> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final loadedAccounts = await _accountService.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = loadedAccounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar contas: $e')));
      }
    }
  }

  Future<void> _saveAccountsList(List<String> updatedList) async {
    try {
      await _accountService.saveAccounts(updatedList);
      setState(() {
        _accounts = updatedList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar alterações: $e')),
        );
      }
    }
  }

  void _showAccountDialog({String? oldName, int? index}) {
    final controller = TextEditingController(text: oldName);
    final isEditing = oldName != null && index != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar conta' : 'Nova conta'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da conta',
              hintText: 'Ex: Carteira, Banco, Ativos',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                final updatedList = List<String>.from(_accounts);
                if (isEditing) {
                  updatedList[index] = newName;
                } else {
                  if (updatedList.contains(newName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Esta conta já existe.')),
                    );
                    return;
                  }
                  updatedList.add(newName);
                }

                _saveAccountsList(updatedList);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(int index) {
    final accountName = _accounts[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar conta'),
          content: Text(
            'Tem a certeza que pretende eliminar a conta "$accountName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final updatedList = List<String>.from(_accounts)
                  ..removeAt(index);
                _saveAccountsList(updatedList);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerir contas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma conta criada.\nImporte do Cashew ou toque em "+".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(account),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showAccountDialog(oldName: account, index: index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteAccount(index),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
