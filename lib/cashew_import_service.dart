// lib/cashewcategory_import_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CashewCategoryImportResult {
  final Map<String, List<String>>? categories;
  final String? errorMessage;

  const CashewCategoryImportResult({this.categories, this.errorMessage});

  bool get success => categories != null;
}

class CashewCategoryImportService {
  Future<CashewCategoryImportResult> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return const CashewCategoryImportResult(errorMessage: 'cancelled');
    }

    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (!data.containsKey('categories')) {
        return const CashewCategoryImportResult(
          errorMessage: 'Ficheiro inválido: não contém categorias do Cashew.',
        );
      }

      final raw = data['categories'] as Map<String, dynamic>;

      if (raw.isEmpty) {
        return const CashewCategoryImportResult(
          errorMessage: 'O ficheiro não contém nenhuma categoria.',
        );
      }

      final categories = raw.map((key, value) {
        final subs = (value as List<dynamic>).whereType<String>().toList();
        return MapEntry(key, subs);
      });

      return CashewCategoryImportResult(categories: categories);
    } catch (_) {
      return const CashewCategoryImportResult(
        errorMessage: 'Erro ao ler o ficheiro. Verifique se é um JSON válido.',
      );
    }
  }
}
