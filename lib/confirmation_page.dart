// lib/confirmation_page.dart

import 'package:flutter/material.dart';
import 'fatura_model.dart';
import 'profile_service.dart';
import 'cashew_launcher.dart';
import 'merchant_profile.dart';
import 'category_management_service.dart';

class ConfirmationPage extends StatefulWidget {
  final Fatura fatura;
  const ConfirmationPage({super.key, required this.fatura});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final ProfileService _profileService = ProfileService();
  final CashewLauncher _cashewLauncher = CashewLauncher();
  final CategoryManagementService _categoryService =
      CategoryManagementService();

  MerchantProfile? _profile;
  Map<String, List<String>> _allCategories = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loadedProfile = await _profileService.getProfile(
        widget.fatura.nifComerciante,
      );
      final loadedCategories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = loadedCategories;
          _profile =
              loadedProfile ??
              MerchantProfile(name: 'Desconhecido', category: '');
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

  // --- Regista no Cashew e guarda o perfil ---
  Future<void> _registerTransaction() async {
    if (_profile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Guarda o perfil atualizado
      await _profileService.saveProfile(
        widget.fatura.nifComerciante,
        _profile!,
      );
      // Lança o Cashew
      await _cashewLauncher.launchCashew(
        fatura: widget.fatura,
        category: _profile!.category,
        subcategory: _profile!.subcategory,
        title: _profile!.name,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveProfileOnly() async {
    if (_profile == null) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      await _profileService.saveProfile(
        widget.fatura.nifComerciante,
        _profile!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comerciante "${_profile!.name}" guardado com sucesso!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showEditDialog() {
    if (_profile == null) return;

    final localNameController = TextEditingController(text: _profile!.name);

    String? selectedCategory = _profile!.category.isEmpty
        ? null
        : _profile!.category;
    String? selectedSubcategory = _profile!.subcategory;

    if (selectedCategory != null &&
        !_allCategories.containsKey(selectedCategory)) {
      selectedCategory = null;
      selectedSubcategory = null;
    }
    if (selectedSubcategory != null &&
        !(_allCategories[selectedCategory]?.contains(selectedSubcategory) ??
            false)) {
      selectedSubcategory = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableSubcategories =
                _allCategories[selectedCategory] ?? [];

            return AlertDialog(
              title: const Text('Editar Perfil do Comerciante'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: localNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Comerciante',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      hint: const Text('Nenhuma (Selecionar no Cashew)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma (Selecionar no Cashew)'),
                        ),
                        ..._allCategories.keys.map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedCategory = newValue;
                          selectedSubcategory = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 20),
                    if (selectedCategory != null &&
                        availableSubcategories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubcategory,
                        hint: const Text('Nenhuma'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Nenhuma'),
                          ),
                          ...availableSubcategories.map(
                            (sub) =>
                                DropdownMenuItem(value: sub, child: Text(sub)),
                          ),
                        ],
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedSubcategory = newValue;
                          });
                        },
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
                  onPressed: () {
                    if (localNameController.text.isNotEmpty) {
                      setState(() {
                        _profile = MerchantProfile(
                          name: localNameController.text,
                          category: selectedCategory ?? '',
                          subcategory: selectedSubcategory,
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Confirmar Alterações'),
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
      appBar: AppBar(
        title: const Text('Confirmar Despesa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Nome/Categoria',
            onPressed: _isLoading ? null : _showEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.store, size: 40),
                      title: Text(
                        _profile?.name ?? 'Carregando...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text('NIF: ${widget.fatura.nifComerciante}'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.category, size: 40),
                      title: const Text('Categoria'),
                      subtitle: Text(
                        _profile?.category.isEmpty ?? true
                            ? 'Não definida'
                            : '${_profile!.category}${_profile!.subcategory != null ? ' > ${_profile!.subcategory}' : ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.euro, size: 40),
                      title: const Text('Valor Total'),
                      subtitle: Text(
                        '${widget.fatura.valorTotal.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Registar no Cashew',
                              style: TextStyle(fontSize: 18),
                            ),
                      onPressed: _isProcessing ? null : _registerTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Apenas Guardar Comerciante'),
                      onPressed: _isProcessing ? null : _saveProfileOnly,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 16.0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
