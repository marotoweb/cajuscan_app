// lib/category_management_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryManagementService {
  static const String _categoriesKey = 'app_categories';

  // Agora carrega os padrões automaticamente na primeira execução.
  Future<Map<String, List<String>>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);

    if (jsonString != null) {
      // Se já existem dados, descodifica e retorna.
      final Map<String, dynamic> decodedMap = json.decode(jsonString);
      return decodedMap.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
    } else {
      // --- Primeira execução ---
      // Se não há dados, carrega os padrões, guarda-os e retorna-os.
      final defaultCategories = getDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  // Função que define as categorias padrão.
  Map<String, List<String>> getDefaultCategories() {
    return {
      'Alimentação': [
        'Almoço',
        'Jantar',
        'Café',
        'Água',
        'Lanche',
        'Delivery',
        'Takeaway',
      ],
      'Compras': [
        'Amazon',
        'Continente',
        'Lidl',
        'Pingo Doce',
        'IKEA',
        'Zara',
        'H&M',
        'Primark',
        'Fnac',
        'Worten',
      ],
      'Casa': [
        'Renda',
        'Condomínio',
        'Manutenção',
        'Limpeza',
        'Móveis',
        'Decoração',
        'Reparações',
      ],
      'Energia': ['Eletricidade', 'Gás', 'Água'],
      'Comunicações': ['Telemóvel', 'Nuvem', 'Internet', 'TV'],
      'Lazer': [
        'Cinema',
        'Teatro',
        'Concertos',
        'Parques',
        'Viagens',
        'Hotéis',
      ],
      'Educação': ['Livros', 'Cursos', 'Escola', 'Universidade'],
      'Roupas': ['Casual', 'Formal', 'Desporto', 'Calçado', 'Acessórios'],
      'Beleza': ['Cabeleireiro', 'Estética', 'Cosméticos'],
      'Animais': ['Ração', 'Veterinário', 'Acessórios'],
      'Filhos': ['Fraldas', 'Brinquedos', 'Roupas', 'Educação'],
      'Impostos': ['IRS', 'IMI', 'IVA', 'Outros'],
      'Saúde': ['Farmácia', 'Dentista', 'Lentes'],
      'Transporte': [
        'Combustível',
        'Portagens',
        'Manutenção',
        'Estacionamento',
        'Seguro',
        'Impostos',
      ],
      'Outros': [],
    };
  }

  Future<void> saveCategories(Map<String, List<String>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(categories);
    await prefs.setString(_categoriesKey, jsonString);
  }

  Future<void> addCategory(String categoryName) async {
    final categories = await getCategories();
    if (!categories.containsKey(categoryName)) {
      categories[categoryName] = [];
      await saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    final categories = await getCategories();
    categories.remove(categoryName);
    await saveCategories(categories);
  }

  Future<void> addSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    final categories = await getCategories();
    if (categories.containsKey(categoryName) &&
        !categories[categoryName]!.contains(subcategoryName)) {
      categories[categoryName]!.add(subcategoryName);
      await saveCategories(categories);
    }
  }

  Future<void> deleteSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    final categories = await getCategories();
    if (categories.containsKey(categoryName)) {
      categories[categoryName]!.remove(subcategoryName);
      await saveCategories(categories);
    }
  }
}
