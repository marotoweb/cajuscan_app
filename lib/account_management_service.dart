// lib/account_management_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountManagementService {
  static const String _accountsKey = 'app_accounts';

  // Recupera todas as contas guardadas
  Future<List<String>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_accountsKey);

    if (jsonString != null) {
      final List<dynamic> decodedList = json.decode(jsonString);
      return decodedList.map((e) => e.toString()).toList();
    } else {
      // Se for a primeira execução, inicializa com contas padrão sugeridas
      final defaultAccounts = getDefaultAccounts();
      await saveAccounts(defaultAccounts);
      return defaultAccounts;
    }
  }

  // Lista padrão para retrocompatibilidade e primeira execução
  List<String> getDefaultAccounts() {
    return ['Carteira', 'Conta Cartão', 'Revolut'];
  }

  // Grava a lista completa de contas
  Future<void> saveAccounts(List<String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(accounts);
    await prefs.setString(_accountsKey, jsonString);
  }

  // Adiciona uma nova conta (evitando duplicados)
  Future<void> addAccount(String accountName) async {
    final accounts = await getAccounts();
    if (!accounts.contains(accountName)) {
      accounts.add(accountName);
      await saveAccounts(accounts);
    }
  }

  // Elimina uma conta
  Future<void> deleteAccount(String accountName) async {
    final accounts = await getAccounts();
    accounts.remove(accountName);
    await saveAccounts(accounts);
  }

  // Edita/Renomeia uma conta
  Future<void> updateAccount(String oldName, String newName) async {
    final accounts = await getAccounts();
    final index = accounts.indexOf(oldName);
    if (index != -1 && !accounts.contains(newName)) {
      accounts[index] = newName;
      await saveAccounts(accounts);
    }
  }
}
