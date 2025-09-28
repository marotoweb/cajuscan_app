// lib/profile_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'merchant_profile.dart';

class ProfileService {
  static const String _prefix = 'nif_';

  // Guarda o perfil completo de um comerciante
  Future<void> saveProfile(String nif, MerchantProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$nif', profile.toJson());
  }

  // Obtém o perfil de um comerciante
  Future<MerchantProfile?> getProfile(String nif) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_prefix$nif');
    if (jsonString != null) {
      return MerchantProfile.fromJson(jsonString);
    }
    return null;
  }

  // --- Obter todos os perfis ---
  Future<Map<String, MerchantProfile>> getAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));

    final Map<String, MerchantProfile> profiles = {};
    for (final key in keys) {
      final nif = key.substring(_prefix.length);
      final profile = await getProfile(nif);
      if (profile != null) {
        profiles[nif] = profile;
      }
    }
    return profiles;
  }

  // --- Apagar um perfil ---
  Future<void> deleteProfile(String nif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$nif');
  }
}
