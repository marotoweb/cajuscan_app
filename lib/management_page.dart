// lib/management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_service.dart';
import 'merchant_profile.dart';
import 'category_management_service.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final ProfileService _profileService = ProfileService();
  final CategoryManagementService _categoryService =
      CategoryManagementService();

  late Future<Map<String, MerchantProfile>> _profilesFuture;
  Map<String, List<String>> _allCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _profilesFuture = _profileService.getAllProfiles();
      _categoryService.getCategories().then((cats) {
        if (mounted) {
          setState(() {
            _allCategories = cats;
          });
        }
      });
    });
  }

  Future<void> _deleteProfile(String nif) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Comerciante'),
        content: const Text(
          'Tem a certeza que deseja apagar este perfil? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _profileService.deleteProfile(nif);
      _loadData();
    }
  }

  void _showEditDialog(String nif, MerchantProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    String? selectedCategory = profile.category.isEmpty
        ? null
        : profile.category;
    String? selectedSubcategory = profile.subcategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subcategories = _allCategories[selectedCategory] ?? [];
            return AlertDialog(
              title: Text('Editar "${profile.name}"'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Comerciante',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      hint: const Text('Nenhuma'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma'),
                        ),
                        ..._allCategories.keys.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (val) => setDialogState(() {
                        selectedCategory = val;
                        selectedSubcategory = null;
                      }),
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    if (subcategories.isNotEmpty) const SizedBox(height: 20),
                    if (subcategories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubcategory,
                        hint: const Text('Nenhuma'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Nenhuma'),
                          ),
                          ...subcategories.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedSubcategory = val),
                        decoration: const InputDecoration(
                          labelText: 'Subcategoria',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final newProfile = MerchantProfile(
                        name: nameController.text,
                        category: selectedCategory ?? '',
                        subcategory: selectedSubcategory,
                      );
                      await _profileService.saveProfile(nif, newProfile);
                      if (mounted) Navigator.of(context).pop();
                      _loadData();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    final nifController = TextEditingController();
    final nameController = TextEditingController();
    String? selectedCategory;
    String? selectedSubcategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subcategories = _allCategories[selectedCategory] ?? [];
            return AlertDialog(
              title: const Text('Adicionar Novo Comerciante'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nifController,
                      decoration: const InputDecoration(
                        labelText: 'NIF (9 dígitos)',
                        counterText: "",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 9,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Comerciante',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      hint: const Text('Categoria (opcional)'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma'),
                        ),
                        ..._allCategories.keys.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (val) => setDialogState(() {
                        selectedCategory = val;
                        selectedSubcategory = null;
                      }),
                    ),
                    if (subcategories.isNotEmpty) const SizedBox(height: 20),
                    if (subcategories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubcategory,
                        hint: const Text('Subcategoria (opcional)'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Nenhuma'),
                          ),
                          ...subcategories.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedSubcategory = val),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nif = nifController.text;
                    final name = nameController.text;
                    if (nif.length != 9) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('O NIF deve ter 9 dígitos.'),
                        ),
                      );
                      return;
                    }
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('O Nome é obrigatório.')),
                      );
                      return;
                    }

                    final existingProfiles = await _profilesFuture;
                    if (existingProfiles.containsKey(nif)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro: Este NIF já existe.'),
                        ),
                      );
                      return;
                    }

                    final newProfile = MerchantProfile(
                      name: name,
                      category: selectedCategory ?? '',
                      subcategory: selectedSubcategory,
                    );
                    await _profileService.saveProfile(nif, newProfile);
                    if (mounted) Navigator.of(context).pop();
                    _loadData();
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comerciantes Guardados')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Adicionar Comerciante',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Map<String, MerchantProfile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar perfis: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Nenhum comerciante guardado.\n\nClique no botão "+" para adicionar o seu primeiro comerciante manualmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final profiles = snapshot.data!;
          final nifs = profiles.keys.toList()
            ..sort((a, b) => profiles[a]!.name.compareTo(profiles[b]!.name));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120.0),
            itemCount: nifs.length,
            itemBuilder: (context, index) {
              final nif = nifs[index];
              final profile = profiles[nif]!;
              final subtitle =
                  'NIF: $nif\nCategoria: ${profile.category.isEmpty ? 'N/A' : profile.category}${profile.subcategory != null ? ' > ${profile.subcategory}' : ''}';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitle),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar',
                        onPressed: () => _showEditDialog(nif, profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Apagar',
                        onPressed: () => _deleteProfile(nif),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
