// lib/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'profile_service.dart';
import 'category_management_service.dart';
import 'merchant_profile.dart';

class BackupService {
  final ProfileService _profileService = ProfileService();
  final CategoryManagementService _categoryService =
      CategoryManagementService();

  // --- Exportação ---
  Future<void> exportData() async {
    try {
      // Recolher todos os dados
      final profiles = await _profileService.getAllProfiles();
      final categories = await _categoryService.getCategories();

      final backupData = {
        'backup_date': DateTime.now().toIso8601String(),
        'profiles': profiles.map((key, value) => MapEntry(key, value.toMap())),
        'categories': categories,
      };

      final jsonString = json.encode(backupData);
      final Uint8List bytes = utf8.encode(jsonString);

      // Usar o flutter_file_dialog para guardar o ficheiro
      final params = SaveFileDialogParams(
        data: bytes,
        fileName: 'cajuscan_backup.json',
      );

      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath == null) {
        // O utilizador cancelou o diálogo de "Guardar como..."
        // Não fazemos nada, é uma ação normal.
      }
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  // --- Importação ---
  Future<String> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return 'Importação cancelada.';
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString);

      final profilesData = backupData['profiles'] as Map<String, dynamic>?;
      final categoriesData = backupData['categories'] as Map<String, dynamic>?;

      if (profilesData == null || categoriesData == null) {
        throw Exception('Ficheiro de backup inválido ou corrompido.');
      }

      final categoriesToSave = categoriesData.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
      await _categoryService.saveCategories(categoriesToSave);

      for (final entry in profilesData.entries) {
        final nif = entry.key;
        final profileMap = entry.value as Map<String, dynamic>;
        final profile = MerchantProfile.fromMap(profileMap);
        await _profileService.saveProfile(nif, profile);
      }

      return 'Dados importados com sucesso!';
    } catch (e) {
      throw Exception('Erro ao importar dados: $e');
    }
  }
}
