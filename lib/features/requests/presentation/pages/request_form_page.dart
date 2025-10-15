import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/requests/data/datasources/requests_remote_datasource.dart';
import 'package:sum_warehouse/features/requests/domain/entities/request_entity.dart';
import 'package:sum_warehouse/shared/models/request_model.dart' as shared_models;
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Экран создания/редактирования запроса
class RequestFormPage extends ConsumerStatefulWidget {
  final shared_models.RequestModel? request;
  
  const RequestFormPage({
    super.key,
    this.request,
  });

  @override
  ConsumerState<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends ConsumerState<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedStatusCode = 'pending';
  int? _selectedWarehouseId;
  int? _selectedProductTemplateId;

  // Данные из API
  List<WarehouseModel> _warehouses = [];
  List<ProductTemplateModel> _productTemplates = [];
  
  bool get _isEditing => widget.request != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final request = widget.request!;
      _titleController.text = request.title;
      _descriptionController.text = request.description ?? '';
      _quantityController.text = request.quantity.toInt().toString(); // Убираем .0
      _selectedStatusCode = request.status;
      // Безопасно получаем ID из вложенных объектов
      _selectedWarehouseId = request.warehouse?.id;
      _selectedProductTemplateId = request.productTemplate?.id; // Загружаем product_template_id
    } else {
      // Автогенерация заголовка для нового запроса
      _generateTitle();
    }
  }
  
  void _generateTitle() {
    // Не генерируем автоматически, оставляем пустым
    _titleController.text = '';
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Загружаем склады
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;

      // Загружаем шаблоны товаров
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _productTemplates = await templateDataSource.getProductTemplates();

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование Запрос' : 'Создать Запрос'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteRequest,
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: 'Удалить запрос',
            ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Основная информация'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _titleController,
          label: 'Заголовок',
          isRequired: true,
        ),
        const SizedBox(height: 16),

        _buildWarehouseDropdown(),
        const SizedBox(height: 16),

        _buildProductTemplateDropdown(),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _quantityController,
          label: 'Количество',
          isRequired: true,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Статус dropdown полностью удален из интерфейса
        
        _buildTextField(
          controller: _descriptionController,
          label: 'Описание',
          isRequired: true,
          maxLines: 4,
        ),
      ],
    );
  }
  
  
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        helperText: helperText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
      style: const TextStyle(color: Colors.black87),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label обязательно для заполнения';
        }
        return null;
      },
    );
  }
  
  Widget _buildWarehouseDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedWarehouseId,
      decoration: InputDecoration(
        labelText: 'Склад *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      items: _warehouses.map((warehouse) => DropdownMenuItem(
        value: warehouse.id,
        child: Text(warehouse.name),
      )).toList(),
      onChanged: (warehouseId) {
        setState(() {
          _selectedWarehouseId = warehouseId;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите склад';
        }
        return null;
      },
    );
  }

  Widget _buildProductTemplateDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedProductTemplateId,
      decoration: InputDecoration(
        labelText: 'Шаблон товара *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      items: _productTemplates.map((template) => DropdownMenuItem(
        value: template.id,
        child: Text(template.name),
      )).toList(),
      onChanged: (templateId) {
        setState(() {
          _selectedProductTemplateId = templateId;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите шаблон товара';
        }
        return null;
      },
    );
  }
  
  
  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(

      value: _selectedStatusCode,
      decoration: InputDecoration(
        labelText: 'Статус *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Ожидает рассмотрения')),
        DropdownMenuItem(value: 'completed', child: Text('Одобрен')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedStatusCode = value;
        });
      },
    );
  }
  
  Widget _buildBottomButtons() {
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final isAdmin = currentUserRole == UserRole.admin;
    
    return Column(
      children: [
        // Кнопка смены статуса для администратора (только в режиме редактирования)
        if (_isEditing && isAdmin) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleRequestStatus,
              icon: Icon(
                _selectedStatusCode == 'pending' ? Icons.check_circle : Icons.pending,
                size: 20,
              ),
              label: Text(_selectedStatusCode == 'pending' ? 'Одобрить' : 'На рассмотрение'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedStatusCode == 'pending' ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Основные кнопки
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
                onPressed: _isLoading ? null : _saveRequest,
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
    );
  }
  

  
  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      
      
      if (_isEditing) {
        // Обновление существующего запроса
        final updateRequest = shared_models.UpdateRequestRequest(
          warehouseId: _selectedWarehouseId!,
          productTemplateId: _selectedProductTemplateId!,
          title: _titleController.text,
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          // status НЕ отправляем при обновлении через форму
        );

        await dataSource.updateRequest(widget.request!.id, updateRequest);
      } else {
        // Создание нового запроса
        final createRequest = shared_models.CreateRequestRequest(
          warehouseId: _selectedWarehouseId!,
          productTemplateId: _selectedProductTemplateId!,
          title: _titleController.text,
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          priority: shared_models.RequestPriority.normal,
          // status НЕ отправляем - убран параметр
        );

        await dataSource.createRequest(createRequest);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Запрос "${_titleController.text}" обновлен' 
                : 'Запрос "${_titleController.text}" создан'),
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
  
  /// Переключение статуса запроса (pending <-> approved)
  Future<void> _toggleRequestStatus() async {
    if (!_isEditing) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      final requestId = widget.request!.id;
      
    if (_selectedStatusCode == 'pending') {
      // Одобрить запрос (pending -> approved)
      // Используем updateRequest вместо processRequest, так как endpoint /process не существует
      await dataSource.updateRequest(
        requestId,
        shared_models.UpdateRequestRequest(
          warehouseId: _selectedWarehouseId!,
          productTemplateId: _selectedProductTemplateId!,
          title: _titleController.text,
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          status: 'approved',
        ),
      );
      _selectedStatusCode = 'approved';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запрос одобрен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
        // Вернуть на рассмотрение (approved -> pending)
        await dataSource.updateRequest(
          requestId,
          shared_models.UpdateRequestRequest(
            warehouseId: _selectedWarehouseId!,
            productTemplateId: _selectedProductTemplateId!,
            title: _titleController.text,
            quantity: int.parse(_quantityController.text),
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            status: 'pending',
          ),
        );
        _selectedStatusCode = 'pending';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Запрос возвращен на рассмотрение'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      // Обновляем UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка смены статуса: $e'),
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
  
  void _deleteRequest() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запрос'),
        content: Text(
          'Вы уверены, что хотите удалить запрос "${widget.request!.title}"?\n\n'
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      await dataSource.deleteRequest(widget.request!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Запрос "${widget.request!.title}" удален'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
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
}