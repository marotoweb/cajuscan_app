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
  final TextEditingController _searchController = TextEditingController();

  Map<String, MerchantProfile> _allProfiles = {};
  List<String> _filteredNifs = [];
  Map<String, List<String>> _allCategories = {};

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final profiles = await _profileService.getAllProfiles();
      final cats = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          _allProfiles = profiles;
          _allCategories = cats;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilter();
    });
  }

  void _applyFilter() {
    // Recolhe e ordena todos os NIFs com base no nome do comerciante
    final sortedNifs = _allProfiles.keys.toList()
      ..sort((a, b) => _allProfiles[a]!.name.compareTo(_allProfiles[b]!.name));

    if (_searchQuery.isEmpty) {
      _filteredNifs = sortedNifs;
    }
    {
      _filteredNifs = sortedNifs.where((nif) {
        final profile = _allProfiles[nif]!;
        final name = profile.name.toLowerCase();
        final category = profile.category.toLowerCase();
        final subcategory = (profile.subcategory ?? '').toLowerCase();
        final nifClean = nif.toLowerCase();

        return name.contains(_searchQuery) ||
            nifClean.contains(_searchQuery) ||
            category.contains(_searchQuery) ||
            subcategory.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _deleteProfile(String nif) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comerciante'),
        content: const Text(
          'Tem a certeza que deseja eliminar este perfil? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

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
      builder: (dialogContext) {
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
                        labelText: 'Nome do comerciante',
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

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subcategories = _allCategories[selectedCategory] ?? [];
            return AlertDialog(
              title: const Text('Adicionar comerciante'),
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
                        labelText: 'Nome do comerciante',
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

                    if (_allProfiles.containsKey(nif)) {
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

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Comerciantes guardados')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Adicionar comerciante',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por nome, NIF ou categoria...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredNifs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Nenhum comerciante encontrado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120.0),
                          itemCount: _filteredNifs.length,
                          itemBuilder: (context, index) {
                            final nif = _filteredNifs[index];
                            final profile = _allProfiles[nif]!;
                            final subtitle =
                                'NIF: $nif\nCategoria: ${profile.category.isEmpty ? 'N/A' : profile.category}${profile.subcategory != null ? ' > ${profile.subcategory}' : ''}';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(subtitle),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar',
                                      onPressed: () =>
                                          _showEditDialog(nif, profile),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar',
                                      onPressed: () => _deleteProfile(nif),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
