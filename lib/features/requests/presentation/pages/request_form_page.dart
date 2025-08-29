import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/requests/data/datasources/requests_remote_datasource.dart';
import 'package:sum_warehouse/features/requests/domain/entities/request_entity.dart';
import 'package:sum_warehouse/shared/models/request_model.dart' as shared_models;
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';

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
  shared_models.RequestPriority _selectedPriority = shared_models.RequestPriority.normal;
  String _selectedStatusCode = 'pending';
  int? _selectedWarehouseId;
  int? _selectedTemplateId;
  
  // Данные из API
  List<WarehouseModel> _warehouses = [];
  List<ProductTemplateModel> _productTemplates = [];
  List<TemplateAttributeModel> _templateAttributes = [];
  
  // Динамические контроллеры для атрибутов
  Map<String, TextEditingController> _attributeControllers = {};
  Map<String, String?> _attributeValues = {};
  
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
    _attributeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final request = widget.request!;
      _titleController.text = request.title;
      _descriptionController.text = request.description ?? '';
      _quantityController.text = request.quantity.toString();
      _selectedPriority = request.priority;
      _selectedStatusCode = request.status;
      // Безопасно получаем ID из вложенных объектов
      _selectedWarehouseId = request.warehouse?.id;
      _selectedTemplateId = request.productTemplate?.id;
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
      final templatesDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final templatesResponse = await templatesDataSource.getProductTemplates(perPage: 100);
      _productTemplates = templatesResponse.data;
      
      // Если редактируем, загружаем атрибуты шаблона
      if (_isEditing && _selectedTemplateId != null) {
        await _loadTemplateAttributes(_selectedTemplateId!);
        await _loadRequestAttributes();
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки данных: $e');
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
  
  Future<void> _loadTemplateAttributes(int templateId) async {
    try {
      final templatesDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _templateAttributes = await templatesDataSource.getTemplateAttributes(templateId);
      
      // Создаем контроллеры для каждого атрибута
      _attributeControllers.clear();
      _attributeValues.clear();
      
      for (final attribute in _templateAttributes) {
        _attributeControllers[attribute.variable] = TextEditingController();
        _attributeValues[attribute.variable] = attribute.defaultValue;
        if (attribute.defaultValue != null) {
          _attributeControllers[attribute.variable]!.text = attribute.defaultValue!;
        }
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки атрибутов шаблона: $e');
    }
  }
  
  Future<void> _loadRequestAttributes() async {
    if (!_isEditing || widget.request == null) return;
    
    try {
      // Проверяем что ID запроса валиден
      final requestId = widget.request!.id;
      if (requestId == null) {
        print('ID запроса равен null, пропускаем загрузку атрибутов');
        return;
      }
      
      // Получаем полную информацию о запросе включая атрибуты
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      final fullRequest = await dataSource.getRequest(requestId);
      
      // TODO: Нужно получить атрибуты запроса из API
      // Пока заглушка - атрибуты не хранятся в RequestEntity
      print('Загружены данные запроса: ${fullRequest.title}');
      
    } catch (e) {
      print('Ошибка загрузки атрибутов запроса: $e');
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
                    if (_templateAttributes.isNotEmpty) ...[
                      _buildProductCharacteristicsSection(),
                      const SizedBox(height: 24),
                    ],
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

        _buildStatusDropdown(),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _descriptionController,
          label: 'Описание',
          isRequired: true,
          maxLines: 4,
        ),
      ],
    );
  }
  
  Widget _buildProductCharacteristicsSection() {
    if (_templateAttributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Характеристики товара'),
        const SizedBox(height: 16),
        ..._templateAttributes.map((attribute) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAttributeField(attribute),
            )),
      ],
    );
  }
  
  Widget _buildAttributeField(TemplateAttributeModel attribute) {
    switch (attribute.attributeType) {
      case AttributeType.text:
      case AttributeType.number:
        return _buildTextField(
          controller: _attributeControllers[attribute.variable]!,
          label: '${attribute.name}${attribute.unit != null ? ' (${attribute.unit})' : ''}',
          isRequired: attribute.isRequired,
          keyboardType: attribute.attributeType == AttributeType.number 
            ? TextInputType.number 
            : TextInputType.text,
          helperText: attribute.name,
        );
      case AttributeType.select:
        return _buildSelectField(attribute);
      case AttributeType.boolean:
        return _buildBooleanField(attribute);
      default:
        return _buildTextField(
          controller: _attributeControllers[attribute.variable]!,
          label: attribute.name,
          isRequired: attribute.isRequired,
        );
    }
  }
  
  Widget _buildSelectField(TemplateAttributeModel attribute) {
    // Попробуем получить опции из разных источников
    List<String> options = [];
    
    if (attribute.selectOptions != null && attribute.selectOptions!.isNotEmpty) {
      options = attribute.selectOptions!;
    } else if (attribute.options != null) {
      // Парсим options в зависимости от типа
      if (attribute.options is List) {
        options = (attribute.options as List).map((e) => e.toString()).toList();
      } else if (attribute.options is String) {
        options = (attribute.options as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } else if (attribute.value != null) {
      // Если value содержит опции
      if (attribute.value is List) {
        options = (attribute.value as List).map((e) => e.toString()).toList();
      } else if (attribute.value is String) {
        options = (attribute.value as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    
    // Если опций нет, используем дефолтные
    if (options.isEmpty) {
      options = ['Опция 1', 'Опция 2', 'Опция 3'];
    }
    
    final currentValue = _attributeValues[attribute.variable];
    
    return DropdownButtonFormField<String>(

      value: options.contains(currentValue) ? currentValue : null,
      decoration: InputDecoration(
        labelText: '${attribute.name}${attribute.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value;
        });
      },
      validator: attribute.isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return '${attribute.name} обязательно для заполнения';
        }
        return null;
      } : null,
    );
  }
  
  Widget _buildBooleanField(TemplateAttributeModel attribute) {
    final currentValue = _attributeValues[attribute.variable] == 'true';
    
    return CheckboxListTile(
      title: Text(attribute.name),
      subtitle: attribute.isRequired ? const Text('*', style: TextStyle(color: Colors.red)) : null,
      value: currentValue,
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value.toString();
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
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

      value: _selectedTemplateId,
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
          _selectedTemplateId = templateId;
        });
        if (templateId != null) {
          _loadTemplateAttributes(templateId);
        } else {
          setState(() {
            _templateAttributes.clear();
            _attributeControllers.clear();
            _attributeValues.clear();
          });
        }
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
    return Row(
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
    );
  }
  

  
  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      
      // Собираем значения атрибутов
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          attributes[entry.key] = value;
        }
      }
      for (final entry in _attributeValues.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          attributes[entry.key] = entry.value;
        }
      }
      
      if (_isEditing) {
        // Обновление существующего запроса
        final updateRequest = shared_models.UpdateRequestRequest(
          warehouseId: _selectedWarehouseId!,
          productTemplateId: _selectedTemplateId!,
          title: _titleController.text,
          quantity: double.parse(_quantityController.text),
          status: _selectedStatusCode,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          attributes: attributes,
        );
        
        await dataSource.updateRequest(widget.request!.id, updateRequest);
      } else {
        // Создание нового запроса
        final createRequest = shared_models.CreateRequestRequest(
          warehouseId: _selectedWarehouseId!,
          productTemplateId: _selectedTemplateId!,
          title: _titleController.text,
          quantity: double.parse(_quantityController.text),
          priority: _selectedPriority,
          status: _selectedStatusCode,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          attributes: attributes,
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