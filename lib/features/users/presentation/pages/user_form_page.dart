import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/users/data/datasources/users_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/user_management_model.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';

/// Экран создания/редактирования пользователя
class UserFormPage extends ConsumerStatefulWidget {
  final UserManagementModel? user;
  
  const UserFormPage({
    super.key,
    this.user,
  });

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.warehouseWorker;
  int? _selectedCompanyId;
  int? _selectedWarehouseId;
  bool _isBlocked = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  
  bool get _isEditing => widget.user != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final user = widget.user!;
      _lastNameController.text = user.lastName ?? '';
      _firstNameController.text = user.firstName ?? '';
      _middleNameController.text = user.middleName ?? '';
      _usernameController.text = user.username ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _selectedRole = user.role;
      _selectedCompanyId = user.companyId;
      _selectedWarehouseId = user.warehouseId;
      _isBlocked = user.isBlocked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать сотрудника' : 'Новый сотрудник'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteUser,
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
                controller: _lastNameController,
                label: 'Фамилия',
                hint: 'Иванов',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Фамилия обязательна';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _firstNameController,
                label: 'Имя',
                hint: 'Иван',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Имя обязательно';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _middleNameController,
                label: 'Отчество',
                hint: 'Иванович',
                isRequired: false,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _usernameController,
                label: 'Логин',
                hint: 'ivanov',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Логин обязателен';
                  }
                  if (value.trim().length < 3) {
                    return 'Логин должен содержать минимум 3 символа';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'user@example.com',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email обязателен';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Телефон',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              
              // Пароль (только при создании нового пользователя)
              if (!_isEditing) ...[
                _buildSectionTitle('Пароль'),
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Пароль',
                  isPasswordVisible: _passwordVisible,
                  onToggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пароль обязателен';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать минимум 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Подтверждение пароля',
                  isPasswordVisible: _confirmPasswordVisible,
                  onToggleVisibility: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              // Роль и привязки
              _buildSectionTitle('Роль и привязки'),
              const SizedBox(height: 16),
              
              _buildRoleDropdown(),
              const SizedBox(height: 16),
              
              _buildCompanyDropdown(),
              const SizedBox(height: 16),
              
              if (_selectedRole == UserRole.warehouseWorker ||
                  _selectedRole == UserRole.salesManager ||
                  _selectedRole == UserRole.operator)
                _buildWarehouseDropdown(),
              const SizedBox(height: 24),
              
              // Статус
              _buildSectionTitle('Статус'),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Заблокирован'),
                subtitle: const Text('Заблокированные сотрудники не могут войти в систему'),
                value: _isBlocked,
                onChanged: (value) => setState(() => _isBlocked = value),
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
                      onPressed: _isLoading ? null : _saveUser,
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
                          : Text(_isEditing ? 'Сохранить' : 'Создать сотрудника'),
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
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: '$label *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
  
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<UserRole>(
        dropdownColor: Colors.white,
      value: _selectedRole,
      onChanged: (value) => setState(() {
        _selectedRole = value!;
        // Сбрасываем склад если роль не требует его
        if (value != UserRole.warehouseWorker) {
          _selectedWarehouseId = null;
        }
      }),
      decoration: InputDecoration(
        labelText: 'Роль *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: UserRole.values.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(_getRoleDisplayName(role)),
        );
      }).toList(),
    );
  }
  
  Widget _buildCompanyDropdown() {
    // Загружаем компании через провайдер
    final companiesAsyncValue = ref.watch(companiesListProvider((search: null, showArchived: false)));
    
    return companiesAsyncValue.when(
      data: (companies) {
        print('🔵 UserFormPage: Загружено компаний: ${companies.length}');
        return DropdownButtonFormField<int>(
          dropdownColor: Colors.white,
          value: _selectedCompanyId,
          onChanged: (value) {
            print('🔵 UserFormPage: Выбрана компания ID: $value');
            setState(() {
              _selectedCompanyId = value;
              // Сбрасываем выбранный склад при изменении компании
              _selectedWarehouseId = null;
            });
          },
          decoration: InputDecoration(
            labelText: 'Компания',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Не выбрано')),
            ...companies.map((company) {
              print('🔵 UserFormPage: Компания: ${company.name} (ID: ${company.id})');
              return DropdownMenuItem(
                value: company.id,
                child: Text(company.name),
              );
            }),
          ],
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
        print('🔴 UserFormPage: Ошибка загрузки компаний: $error');
        print('🔴 UserFormPage: Stack trace: $stack');
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
  
  Widget _buildWarehouseDropdown() {
    if (_selectedCompanyId == null) {
      return DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
        value: null,
        onChanged: null, // Отключаем выбор
        decoration: InputDecoration(
          labelText: 'Склад',
          hintText: 'Сначала выберите компанию',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('Сначала выберите компанию')),
        ],
      );
    }

    return FutureBuilder<List<WarehouseModel>>(
      future: ref.read(warehousesRemoteDataSourceProvider).getWarehouses(companyId: _selectedCompanyId).then((resp) => resp.data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Ошибка загрузки складов', style: TextStyle(color: Colors.red));
        }
        final warehouses = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
          value: _selectedWarehouseId,
          onChanged: (value) => setState(() => _selectedWarehouseId = value),
          decoration: InputDecoration(
            labelText: 'Склад',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Не выбрано')),
            ...warehouses.map((warehouse) => DropdownMenuItem(
              value: warehouse.id,
              child: Text(warehouse.name),
            )),
          ],
        );
      },
    );
  }
  
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.operator:
        return 'Оператор';
      case UserRole.warehouseWorker:
        return 'Работник склада';
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }
  
  void _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(usersRemoteDataSourceProvider);
      
      if (_isEditing) {
        // Обновление существующего пользователя
        final updateRequest = UpdateUserRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          middleName: _middleNameController.text.isEmpty ? null : _middleNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          role: _selectedRole,
          isBlocked: _isBlocked,
          companyId: _selectedCompanyId,
          warehouseId: (_selectedRole == UserRole.warehouseWorker)
              ? _selectedWarehouseId
              : null,
        );
        
        await dataSource.updateUser(widget.user!.id, updateRequest);
      } else {
        // Создание нового пользователя
        final createRequest = CreateUserRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          middleName: _middleNameController.text.isEmpty ? null : _middleNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          password: _passwordController.text,
          role: _selectedRole,
          isBlocked: _isBlocked,
          companyId: _selectedCompanyId,
          warehouseId: (_selectedRole == UserRole.warehouseWorker)
              ? _selectedWarehouseId
              : null,
        );
        
        await dataSource.createUser(createRequest);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Сотрудник обновлен' 
                : 'Сотрудник создан'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
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
  
  void _deleteUser() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сотрудника'),
        content: Text(
          'Вы уверены, что хотите удалить сотрудника "${widget.user!.name}"?\n\n'
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
    
    // TODO: Реализовать удаление через провайдер
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сотрудник "${widget.user!.name}" удален'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(true);
      }
    });
  }
}
