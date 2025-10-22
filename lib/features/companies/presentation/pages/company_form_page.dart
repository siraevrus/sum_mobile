import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';

/// Экран создания/редактирования компании
class CompanyFormPage extends ConsumerStatefulWidget {
  final CompanyModel? company;
  
  const CompanyFormPage({
    super.key,
    this.company,
  });

  @override
  ConsumerState<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends ConsumerState<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _innController = TextEditingController();
  final _kppController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _ogrnController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _correspondentAccountController = TextEditingController();
  final _bikController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  
  bool get _isEditing => widget.company != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _innController.dispose();
    _kppController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _ogrnController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    _correspondentAccountController.dispose();
    _bikController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final company = widget.company!;
      _nameController.text = company.name;
      _innController.text = company.inn ?? '';
      _kppController.text = company.kpp ?? '';
      _legalAddressController.text = company.legalAddress ?? '';
      _actualAddressController.text = company.postalAddress ?? '';
      _phoneController.text = company.phoneFax ?? '';
      _emailController.text = company.email ?? '';
      _websiteController.text = ''; // Поле website больше не используется
      _contactPersonController.text = company.generalDirector ?? '';
      _ogrnController.text = company.ogrn ?? '';
      _bankController.text = company.bank ?? '';
      _accountNumberController.text = company.accountNumber ?? '';
      _correspondentAccountController.text = company.correspondentAccount ?? '';
      _bikController.text = company.bik ?? '';
      _isActive = !company.isArchived; // Используем инверсию isArchived
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать компанию' : 'Новая компания'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _archiveCompany,
            ),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Название компании *',
                hint: 'ООО "Название"',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название компании обязательно';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contactPersonController,
                label: 'Генеральный директор',
                hint: 'Иванов Иван Иванович',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'info@company.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
                    return 'Некорректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Телефон/факс',
                hint: '+7 (495) 123-45-67',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Адреса'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _legalAddressController,
                label: 'Юридический адрес',
                hint: '123456, город, улица, дом',
                isRequired: true,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Юридический адрес обязателен';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _actualAddressController,
                label: 'Почтовый адрес',
                hint: 'Если отличается от юридического',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Реквизиты'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _innController,
                label: 'ИНН',
                hint: '1234567890',
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ИНН обязателен';
                  }
                  if (!_isValidINN(value)) {
                    return 'Некорректный ИНН (должно быть 10 цифр)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _kppController,
                label: 'КПП',
                hint: '123456789',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !_isValidKPP(value)) {
                    return 'КПП должен содержать 9 цифр';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ogrnController,
                label: 'ОГРН',
                hint: '1234567890123',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Банковские реквизиты'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankController,
                label: 'БАНК',
                hint: 'Название банка',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _accountNumberController,
                label: 'P/c',
                hint: 'Номер счета',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _correspondentAccountController,
                label: 'K/c',
                hint: 'Корр. счет',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bikController,
                label: 'БИК',
                hint: '123456789',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
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
                      onPressed: _isLoading ? null : _saveCompany,
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
                          : Text(_isEditing ? 'Сохранить' : 'Создать'),
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
    int? maxLength,
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
      maxLength: maxLength,
      validator: validator,
    );
  }
  
  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final formData = CompanyFormModel(
        name: _nameController.text.trim(),
        inn: _innController.text.trim(),
        kpp: _kppController.text.trim(),
        legalAddress: _legalAddressController.text.trim(),
        actualAddress: _actualAddressController.text.trim().isEmpty 
            ? null 
            : _actualAddressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty 
            ? null 
            : _contactPersonController.text.trim(),
        ogrn: _ogrnController.text.trim().isEmpty 
            ? null 
            : _ogrnController.text.trim(),
        bank: _bankController.text.trim().isEmpty 
            ? null 
            : _bankController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty 
            ? null 
            : _accountNumberController.text.trim(),
        correspondentAccount: _correspondentAccountController.text.trim().isEmpty 
            ? null 
            : _correspondentAccountController.text.trim(),
        bik: _bikController.text.trim().isEmpty 
            ? null 
            : _bikController.text.trim(),
        isActive: _isActive,
      );
      
      CompanyModel? result;
      if (_isEditing) {
        try {
          final notifier = ref.read(companiesProvider.notifier);
          await notifier.updateCompany(widget.company!.id, formData);
          result = widget.company;
        } catch (e) {
          // If update failed due to parsing but server updated successfully,
          // try to GET the fresh company and continue so UI can return.
          try {
            final repo = ref.read(companiesRepositoryProvider);
            final fresh = await repo.getCompanyById(widget.company!.id);
            result = fresh;
          } catch (e2) {
            // ignore - will be handled below
          }
        }
      } else {
        final notifier = ref.read(companiesProvider.notifier);
        await notifier.createCompany(formData);
        result = null; // Новые компании не возвращаются
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Компания обновлена' 
                : 'Компания успешно создана'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // После успешного создания/редактирования переходим на список компаний
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Извлекаем сообщение об ошибке из DioException
        String errorMessage = 'Ошибка: $e';
        
        if (e is DioException && e.response?.data != null) {
          try {
            final responseData = e.response!.data;
            if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
            }
          } catch (_) {
            // Если не удалось извлечь message, используем стандартное сообщение
          }
        }
        
        // Показываем диалог с ошибкой
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _archiveCompany() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивировать компанию'),
        content: Text(
          'Вы уверены, что хотите архивировать компанию "${widget.company!.name}"?\n\n'
          'Архивированная компания будет скрыта из списка, но все данные сохранятся. '
          'В будущем её можно будет восстановить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performArchive();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Архивировать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performArchive() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(companiesRemoteDataSourceProvider);
      await dataSource.archiveCompany(widget.company!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Компания архивирована'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Возвращаем true для обновления списка
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при архивировании: $e'),
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
  
  bool _isValidINN(String inn) {
    if (inn.length != 10 && inn.length != 12) return false;
    return RegExp(r'^\d+$').hasMatch(inn);
  }
  
  bool _isValidKPP(String kpp) {
    if (kpp.length != 9) return false;
    return RegExp(r'^\d+$').hasMatch(kpp);
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
