// lib/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _confirmOnCashewKey = 'confirm_on_cashew';

  // Obtém a preferência do utilizador. O valor padrão é 'false' (registo direto).
  Future<bool> getConfirmOnCashew() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_confirmOnCashewKey) ?? false;
  }

  // Guarda a preferência do utilizador.
  Future<void> setConfirmOnCashew(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmOnCashewKey, value);
  }
}
