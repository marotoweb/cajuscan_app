// lib/cashew_import_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class CashewImportResult {
  final Map<String, List<String>>? categories;
  final List<String>? accounts;
  final String? errorMessage;

  const CashewImportResult({this.categories, this.accounts, this.errorMessage});

  bool get success => categories != null || accounts != null;
}

class CashewImportService {
  Future<CashewImportResult> pickAndParse() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        return const CashewImportResult(errorMessage: 'cancelled');
      }

      final file = result.files.first;
      String jsonString;

      if (kIsWeb) {
        if (file.bytes == null) {
          return const CashewImportResult(
            errorMessage: 'Não foi possível ler os dados do ficheiro na Web.',
          );
        }
        jsonString = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          return const CashewImportResult(
            errorMessage: 'Caminho do ficheiro inválido.',
          );
        }
        final ioFile = File(file.path!);
        jsonString = await ioFile.readAsString();
      }

      return parseJson(jsonString);
    } catch (e) {
      return CashewImportResult(
        errorMessage: 'Erro ao selecionar o ficheiro: $e',
      );
    }
  }

  CashewImportResult parseJson(String jsonString) {
    try {
      final data = json.decode(jsonString);
      if (data is! Map<String, dynamic>) {
        return const CashewImportResult(
          errorMessage: 'Formato JSON inválido. Deve ser um objeto.',
        );
      }

      Map<String, List<String>>? importedCategories;
      List<String>? importedAccounts;

      // Parse das categorias
      if (data.containsKey('categories')) {
        final rawCategories = data['categories'];
        if (rawCategories is Map<String, dynamic> && rawCategories.isNotEmpty) {
          final Map<String, List<String>> tempCategories = {};

          for (final entry in rawCategories.entries) {
            final key = entry.key;
            final val = entry.value;
            if (val is List) {
              tempCategories[key] = val
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            } else {
              tempCategories[key] = [];
            }
          }

          if (tempCategories.isNotEmpty) {
            importedCategories = tempCategories;
          }
        }
      }

      // Parse das contas
      if (data.containsKey('accounts')) {
        final rawAccounts = data['accounts'];
        if (rawAccounts is List) {
          final parsedAccounts = rawAccounts
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (parsedAccounts.isNotEmpty) {
            importedAccounts = parsedAccounts;
          }
        }
      }

      if (importedCategories == null && importedAccounts == null) {
        return const CashewImportResult(
          errorMessage:
              'O ficheiro não contém chaves de categorias ou contas válidas com dados do Cashew.',
        );
      }

      return CashewImportResult(
        categories: importedCategories,
        accounts: importedAccounts,
      );
    } catch (e) {
      return CashewImportResult(
        errorMessage: 'Erro ao processar a estrutura do JSON: $e',
      );
    }
  }
}
