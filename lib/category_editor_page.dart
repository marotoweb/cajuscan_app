// lib/category_editor_page.dart
import 'package:flutter/material.dart';
import 'category_management_service.dart';

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key});

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  Map<String, List<String>> _categories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    final loadedCategories = await _categoryService.getCategories();
    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog({String? categoryToEdit}) async {
    final nameController = TextEditingController(text: categoryToEdit);
    final isEditing = categoryToEdit != null;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Categoria' : 'Nova Categoria'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da Categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (isEditing) {
        // Lógica de renomear (apagar o antigo, adicionar o novo)
        final subcategories = _categories[categoryToEdit]!;
        await _categoryService.deleteCategory(categoryToEdit);
        await _categoryService.addCategory(newName);
        for (var sub in subcategories) {
          await _categoryService.addSubcategory(newName, sub);
        }
      } else {
        await _categoryService.addCategory(newName);
      }
      _loadCategories();
    }
  }

  Future<void> _showAddSubcategoryDialog(String categoryName) async {
    final nameController = TextEditingController();
    final newSubcategoryName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Subcategoria para "$categoryName"'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da Subcategoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Adicionar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (newSubcategoryName != null && newSubcategoryName.isNotEmpty) {
      await _categoryService.addSubcategory(categoryName, newSubcategoryName);
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
          'Tem a certeza que quer apagar a categoria "$categoryName" e todas as suas subcategorias?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Apagar'),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      await _categoryService.deleteCategory(categoryName);
      _loadCategories();
    }
  }

  Future<void> _deleteSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    await _categoryService.deleteSubcategory(categoryName, subcategoryName);
    _loadCategories();
  }

  Future<void> _restoreDefaultCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Categorias'),
        content: const Text(
          'Isto irá substituir a sua lista de categorias atual pela lista padrão. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      final defaultCategories = _categoryService.getDefaultCategories();
      await _categoryService.saveCategories(defaultCategories);
      _loadCategories();
    }
  }

  Future<void> _deleteAllCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('APAGAR TUDO?'),
        content: const Text(
          'Esta ação é irreversível e irá apagar TODAS as suas categorias e subcategorias. Tem a certeza absoluta?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Apagar Tudo'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _categoryService.saveCategories({}); // Guarda um mapa vazio
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryKeys = _categories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerir Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Apagar Tudo',
            onPressed: _isLoading || _categories.isEmpty
                ? null
                : _deleteAllCategories,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restaurar Padrão',
            onPressed: _isLoading ? null : _restoreDefaultCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        tooltip: 'Nova Categoria',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          // Já não precisa do botão de restauro aqui, pois está na AppBar.
          ? const Center(child: Text('A sua lista de categorias está vazia.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120.0),
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final category = categoryKeys[index];
                final subcategories = _categories[category]!;
                return ExpansionTile(
                  key: PageStorageKey(category),
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(Icons.folder_open),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Renomear',
                        onPressed: () =>
                            _showAddDialog(categoryToEdit: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Apagar',
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                  children: [
                    ...subcategories.map(
                      (sub) => ListTile(
                        title: Text(sub),
                        leading: const Icon(Icons.label_outline, size: 18),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _deleteSubcategory(category, sub),
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Adicionar Subcategoria...'),
                      leading: const Icon(Icons.add, color: Colors.green),
                      onTap: () => _showAddSubcategoryDialog(category),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
