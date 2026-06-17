// lib/account_management_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AccountManagementService {
  static const String _accountsKey = 'cashew_accounts';

  // Recupera todas as contas guardadas
  Future<List<String>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String>? stringList = prefs.getStringList(_accountsKey);
    if (stringList != null) {
      return stringList;
    }

    // Se for a primeira execução e não houver dados, inicializa com contas padrão
    final defaultAccounts = getDefaultAccounts();
    await saveAccounts(defaultAccounts);
    return defaultAccounts;
  }

  // Garante que este método está aqui dentro da classe
  List<String> getDefaultAccounts() {
    return ['Carteira', 'Conta Cartão', 'Revolut'];
  }

  // Grava a lista completa de contas usando o método nativo otimizado
  Future<void> saveAccounts(List<String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_accountsKey, accounts);
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
