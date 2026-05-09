// lib/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _confirmOnCashewKey = 'confirm_on_cashew';
  static const String _continuousScanKey = 'continuous_scan';

  /// Obtém a preferência de confirmação.
  /// Valor padrão alterado para 'true' para garantir segurança na primeira utilização.
  Future<bool> getConfirmOnCashew() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_confirmOnCashewKey) ?? true;
  }

  // Guarda a preferência do utilizador.
  Future<void> setConfirmOnCashew(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmOnCashewKey, value);
  }

  /// Obtém a preferência de Scan Contínuo.
  /// Por defeito 'true' para maximizar a produtividade inicial.
  Future<bool> getContinuousScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_continuousScanKey) ?? true;
  }

  Future<void> setContinuousScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_continuousScanKey, value);
  }
}
