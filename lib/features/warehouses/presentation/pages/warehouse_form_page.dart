import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';

/// Экран создания/редактирования склада
class WarehouseFormPage extends ConsumerStatefulWidget {
  final WarehouseModel? warehouse;
  
  const WarehouseFormPage({
    super.key,
    this.warehouse,
  });

  @override
  ConsumerState<WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends ConsumerState<WarehouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  int? _selectedCompanyId;
  bool _isActive = true;
  
  bool get _isEditing => widget.warehouse != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final warehouse = widget.warehouse!;
      _nameController.text = warehouse.name;
      _addressController.text = warehouse.address;
      _phoneController.text = warehouse.phone ?? '';
      _managerController.text = warehouse.manager ?? '';
      _notesController.text = warehouse.notes ?? '';
      _selectedCompanyId = warehouse.companyId;
      _isActive = warehouse.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать склад' : 'Новый склад'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteWarehouse,
            ),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Название склада',
                hint: 'Введите название склада',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название склада обязательно';
                  }
                  if (value.trim().length < 2) {
                    return 'Название должно содержать минимум 2 символа';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Адрес',
                hint: 'Введите полный адрес склада',
                isRequired: true,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Адрес обязателен';
                  }
                  if (value.trim().length < 5) {
                    return 'Введите корректный адрес';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Компания
              _buildCompanyDropdown(),
              const SizedBox(height: 24),
              

              
              // Статус
              _buildSectionTitle('Статус'),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Активный склад'),
                subtitle: const Text('Неактивные склады не отображаются в списках'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppColors.primary,
              ),
              
              const SizedBox(height: 32),
              
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveWarehouse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? 'Сохранить' : 'Создать склад'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
  
  Widget _buildCompanyDropdown() {
    // Загружаем компании через провайдер
    final companiesAsyncValue = ref.watch(companiesListProvider((search: null, showArchived: false)));
    
    return companiesAsyncValue.when(
      data: (companies) {
        print('🔵 Загружено компаний: ${companies.length}');
        return DropdownButtonFormField<int>(
          dropdownColor: Colors.white,
          value: _selectedCompanyId,
          onChanged: (value) {
            print('🔵 Выбрана компания ID: $value');
            setState(() => _selectedCompanyId = value);
          },
          decoration: InputDecoration(
            labelText: 'Компания *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          validator: (value) {
            if (value == null) {
              return 'Выберите компанию';
            }
            return null;
          },
          items: companies.isEmpty 
            ? [
                const DropdownMenuItem(
                  value: null,
                  enabled: false,
                  child: Text('Нет доступных компаний'),
                )
              ]
            : companies.map((company) {
                print('🔵 Компания: ${company.name} (ID: ${company.id})');
                return DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                );
              }).toList(),
        );
      },
      loading: () => Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) {
        print('🔴 Ошибка загрузки компаний: $error');
        print('🔴 Stack trace: $stack');
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Ошибка загрузки компаний: $error',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }
  
  void _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      
      if (_isEditing) {
        // Обновление существующего склада
        final updateRequest = UpdateWarehouseRequest(
          name: _nameController.text,
          address: _addressController.text,
          companyId: _selectedCompanyId!,
        );
        
        await dataSource.updateWarehouse(widget.warehouse!.id, updateRequest);
      } else {
        // Создание нового склада
        final createRequest = CreateWarehouseRequest(
          name: _nameController.text,
          address: _addressController.text,
          companyId: _selectedCompanyId!,
        );
        
        await dataSource.createWarehouse(createRequest);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Склад "${_nameController.text}" обновлен' 
                : 'Склад "${_nameController.text}" создан'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _deleteWarehouse() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить склад'),
        content: Text(
          'Вы уверены, что хотите удалить склад "${widget.warehouse!.name}"?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performDelete() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      await dataSource.deleteWarehouse(widget.warehouse!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Склад "${widget.warehouse!.name}" успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Возвращаем true для обновления списка
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
