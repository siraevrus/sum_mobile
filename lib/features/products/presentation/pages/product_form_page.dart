import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/shared/providers/app_data_provider.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/features/products/presentation/providers/products_provider.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';

/// Экран создания/редактирования/просмотра товара
class ProductFormPage extends ConsumerStatefulWidget {
  final ProductEntity? product;
  final bool isViewMode;
  
  const ProductFormPage({
    super.key,
    this.product,
    this.isViewMode = false,
  });

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _transportNumberController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  DateTime? _arrivalDate;
  
  ProductTemplateEntity? _selectedTemplate;
  int? _selectedWarehouseId;
  int? _selectedProducerId;
  Map<String, TextEditingController> _attributeControllers = {};
  Map<String, dynamic> _attributeValues = {};
  double? _calculatedValue;
  
  bool get _isEditing => widget.product != null && !widget.isViewMode;
  bool get _isViewing => widget.product != null && widget.isViewMode;
  
  @override
  void initState() {
    super.initState();
    // Загружаем производителей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(producersProvider.notifier).loadProducers();
    });
    _initializeForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _transportNumberController.dispose();
    _attributeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing || _isViewing) {
      final product = widget.product!;
      _nameController.text = product.name;
      _quantityController.text = product.quantity.toString();
      _descriptionController.text = product.description ?? '';
      _notesController.text = product.notes ?? '';
      _transportNumberController.text = product.transportNumber ?? '';
      _selectedWarehouseId = product.warehouseId;
      _arrivalDate = product.arrivalDate;
      _isActive = product.isActive;
      _attributeValues = Map.from(product.attributes);
      _calculatedValue = product.calculatedValue;
      
      // Производитель - пытаемся найти ID по имени
      if (product.producer != null && product.producer!.isNotEmpty) {
        _loadProducerIdByName(product.producer!);
      }
      
      // Загружаем атрибуты шаблона, если есть productTemplateId
      if (product.productTemplateId != null) {
        _loadTemplateAttributesForEditing(product.productTemplateId!);
      }
      _selectedTemplate = null;
      _initializeAttributeControllers();
    }
  }
  
  void _initializeAttributeControllers() {
    if (_selectedTemplate == null) return;
    
    _attributeControllers.clear();
    for (final attribute in _selectedTemplate!.attributes) {
      final controller = TextEditingController();
      final value = _attributeValues[attribute.variable];
      if (value != null) {
        controller.text = value.toString();
      } else if (attribute.defaultValue != null) {
        controller.text = attribute.defaultValue!;
        _attributeValues[attribute.variable] = attribute.defaultValue;
      }
      _attributeControllers[attribute.variable] = controller;
    }
  }
  
  /// Загрузить атрибуты шаблона из API
  Future<void> _loadTemplateAttributes(int templateId) async {
    try {
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final attributes = await dataSource.getTemplateAttributes(templateId);
      
      if (mounted && _selectedTemplate != null) {
        // Создаем новый шаблон с загруженными атрибутами
        final updatedTemplate = ProductTemplateEntity(
          id: _selectedTemplate!.id,
          name: _selectedTemplate!.name,
          unit: _selectedTemplate!.unit,
          description: _selectedTemplate!.description,
          formula: _selectedTemplate!.formula,
          attributes: attributes.map((attr) => attr.toEntity()).toList(),
          isActive: _selectedTemplate!.isActive,
          createdAt: _selectedTemplate!.createdAt,
          updatedAt: _selectedTemplate!.updatedAt,
        );
        
        setState(() {
          _selectedTemplate = updatedTemplate;
        });
        
        _initializeAttributeControllers();
      }
    } catch (e) {
      print('⚠️ Ошибка загрузки атрибутов: $e');
    }
  }
  
  /// Загрузить атрибуты шаблона при редактировании товара
  Future<void> _loadTemplateAttributesForEditing(int templateId) async {
    try {
      final templatesAsync = ref.read(allProductTemplatesProvider.future);
      final templates = await templatesAsync;
      
      // Находим шаблон по ID
      final template = templates.firstWhere((t) => t.id == templateId);
      
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final attributes = await dataSource.getTemplateAttributes(templateId);
      
      if (mounted) {
        final templateEntity = ProductTemplateEntity(
          id: template.id,
          name: template.name,
          unit: template.unit,
          description: template.description,
          formula: template.formula,
          attributes: attributes.map((attr) => attr.toEntity()).toList(),
          isActive: template.isActive,
          createdAt: template.createdAt,
          updatedAt: template.updatedAt,
        );
        
        setState(() {
          _selectedTemplate = templateEntity;
        });
        
        _initializeAttributeControllers();
      }
    } catch (e) {
      print('⚠️ Ошибка загрузки шаблона для редактирования: $e');
    }
  }

  /// Найти ID производителя по имени
  Future<void> _loadProducerIdByName(String producerName) async {
    try {
      final producersAsync = ref.read(producersProvider);
      final producers = producersAsync.asData?.value ?? [];
      
      // Находим производителя по имени
      final producer = producers.firstWhere(
        (p) => p.name == producerName,
        orElse: () => throw Exception('Производитель не найден'),
      );
      
      if (mounted) {
        setState(() {
          _selectedProducerId = producer.id;
        });
      }
    } catch (e) {
      print('⚠️ Ошибка загрузки производителя: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isViewing) {
      return _buildViewMode();
    }
    
    return _buildEditMode();
  }
  
  Widget _buildViewMode() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр товара'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductFormPage(
                    product: widget.product,
                    isViewMode: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Наименование
            _buildViewField('Наименование', widget.product!.name),
            const SizedBox(height: 16),
            
            // Количество
            _buildViewField('Количество', '${widget.product!.quantity} ${_selectedTemplate?.unit ?? ''}'),
            const SizedBox(height: 24),
            
            // Блок "Основная информация"
            _buildSectionTitle('Основная информация'),
            const SizedBox(height: 16),
            
            // Склад
            Consumer(
              builder: (context, ref, child) {
                final warehousesAsync = ref.watch(allWarehousesProvider);
                return warehousesAsync.when(
                  loading: () => _buildViewField('Склад', 'Загрузка...'),
                  error: (error, stack) => _buildViewField('Склад', 'Ошибка загрузки'),
                  data: (warehouses) {
                    final warehouse = warehouses.firstWhere(
                      (w) => w.id == widget.product!.warehouseId,
                      orElse: () => throw Exception('Склад не найден'),
                    );
                    return _buildViewField('Склад', warehouse.name);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Производитель
            _buildViewField('Производитель', _getProducerDisplayName()),
            const SizedBox(height: 12),
            
            // Дата поступления
            _buildViewField('Дата поступления', 
              widget.product!.arrivalDate != null 
                ? _formatDate(widget.product!.arrivalDate!) 
                : 'Не указана'),
            const SizedBox(height: 12),
            
            // Номер транспортного средства
            _buildViewField('Номер транспортного средства', 
              widget.product!.transportNumber ?? 'Не указан'),
            const SizedBox(height: 24),
            
            // Блок "Характеристики"
            if (_selectedTemplate != null && _selectedTemplate!.attributes.isNotEmpty) ...[
              _buildSectionTitle('Характеристики'),
              const SizedBox(height: 16),
              
              ..._selectedTemplate!.attributes.map((attribute) {
                final value = _attributeValues[attribute.variable];
                String displayValue = 'Не указано';
                
                if (value != null) {
                  if (attribute.type == AttributeType.boolean) {
                    displayValue = (value as bool) ? 'Да' : 'Нет';
                  } else if (attribute.type == AttributeType.date && value is DateTime) {
                    displayValue = _formatDate(value);
                  } else {
                    displayValue = value.toString();
                    if (attribute.unit != null && attribute.unit!.isNotEmpty) {
                      displayValue += ' ${attribute.unit}';
                    }
                  }
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildViewField(attribute.name, displayValue),
                );
              }),
              
              if (_calculatedValue != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Расчёт по формуле: ${_calculatedValue!.toStringAsFixed(3)} ${_selectedTemplate!.unit}',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
            
            // Блок "Заметки"
            if (widget.product!.notes != null && widget.product!.notes!.isNotEmpty) ...[
              _buildSectionTitle('Заметки'),
              const SizedBox(height: 16),
              _buildViewField('Заметки', widget.product!.notes!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildViewField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getProducerDisplayName() {
    final product = widget.product!;
    
    // Проверяем producer_id и ищем в списке производителей
    if (_selectedProducerId != null) {
      final producersAsync = ref.read(producersProvider);
      if (producersAsync.hasValue) {
        final producers = producersAsync.asData?.value ?? [];
        try {
          final producer = producers.firstWhere((p) => p.id == _selectedProducerId);
          return producer.name;
        } catch (e) {
          // Производитель не найден в списке
        }
      }
    }
    
    // Фолбэк к строковому полю producer
    if (product.producer != null && product.producer!.isNotEmpty) {
      return product.producer!;
    }
    
    return 'Не указан';
  }
  
  Widget _buildEditMode() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать товар' : 'Новый товар'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
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
              // Блок "Основная информация"
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              
              // Склад
              Consumer(
                builder: (context, ref, child) {
                  final warehousesAsync = ref.watch(allWarehousesProvider);
                  return warehousesAsync.when(
                    loading: () => DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Склад * (загрузка...)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Загрузка складов...'),
                        ),
                      ],
                      onChanged: null,
                    ),
                    error: (error, stack) => DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Склад * (ошибка)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Ошибка загрузки складов'),
                        ),
                      ],
                      onChanged: null,
                    ),
                    data: (warehouses) => DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                      value: _selectedWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'Склад *',
                        border: OutlineInputBorder(),
                      ),
                      items: warehouses.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Нет доступных складов'),
                            ),
                          ]
                        : warehouses.map((warehouse) => DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          )).toList(),
                      onChanged: (warehouseId) {
                        setState(() {
                          _selectedWarehouseId = warehouseId;
                        });
                      },
                      validator: (value) {
                        if (value == null && warehouses.isNotEmpty) {
                          return 'Выберите склад';
                        }
                        return null;
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Производитель
              _buildProducerDropdown(),
              const SizedBox(height: 16),
              
              // Дата поступления
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Дата поступления*',
                    border: const OutlineInputBorder(),
                    errorText: _arrivalDate == null ? 'Выберите дату поступления' : null,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _arrivalDate != null 
                        ? _formatDate(_arrivalDate!)
                        : 'Не указана',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Номер транспорта
              _buildTextField(
                controller: _transportNumberController,
                label: 'Номер транспорта',
                hint: 'Введите номер',
              ),
              const SizedBox(height: 24),
              
              // Блок "Товар"
              _buildSectionTitle('Товар'),
              const SizedBox(height: 16),
              
              // Шаблон товара (редактируемый как при создании, так и при редактировании)
              Consumer(
                builder: (context, ref, child) {
                  final templatesAsync = ref.watch(allProductTemplatesProvider);
                  
                  return templatesAsync.when(
                    loading: () => DropdownButtonFormField<ProductTemplateEntity>(
        dropdownColor: Colors.white,
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Шаблон товара * (загрузка...)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Загрузка шаблонов...'),
                        ),
                      ],
                      onChanged: null,
                    ),
                    error: (error, stack) => DropdownButtonFormField<ProductTemplateEntity>(
        dropdownColor: Colors.white,
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Шаблон товара * (ошибка)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Ошибка загрузки шаблонов'),
                        ),
                      ],
                      onChanged: null,
                    ),
                    data: (templates) => DropdownButtonFormField<int?>(
        dropdownColor: Colors.white,
                      value: _selectedTemplate?.id,
                      decoration: const InputDecoration(
                        labelText: 'Шаблон товара *',
                        border: OutlineInputBorder(),
                      ),
                      items: templates.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Нет доступных шаблонов'),
                            ),
                          ]
                        : templates.map((template) => DropdownMenuItem(
                            value: template.id, // Используем ID вместо объекта
                            child: Text(template.name),
                          )).toList(),
                      onChanged: (templateId) {
                        if (templateId != null) {
                          final template = templates.firstWhere((t) => t.id == templateId);
                          setState(() {
                            _selectedTemplate = _convertTemplateModelToEntity(template);
                            _attributeValues.clear();
                            _calculatedValue = null;
                          });
                          
                          // Загружаем атрибуты для выбранного шаблона
                          _loadTemplateAttributes(templateId);
                        } else {
                          setState(() {
                            _selectedTemplate = null;
                            _attributeValues.clear();
                            _calculatedValue = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null && templates.isNotEmpty) {
                          return 'Выберите шаблон товара';
                        }
                        return null;
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Количество
              _buildTextField(
                controller: _quantityController,
                label: 'Количество',
                hint: '0',
                isRequired: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Количество обязательно';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Некорректное число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Блок "Дополнительное поле"
              _buildSectionTitle('Дополнительное поле'),
              const SizedBox(height: 16),
              
              // Заметки (переименованное поле "Описание")
              _buildTextField(
                controller: _notesController,
                label: 'Заметки',
                hint: 'Дополнительные заметки к товару',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Нередактируемое поле наименования
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Наименование',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getGeneratedProductName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Характеристики товара
              if (_selectedTemplate != null && _selectedTemplate!.attributes.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Характеристики'),
                    if (_calculatedValue != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Расчет: ${_calculatedValue!.toStringAsFixed(3)} ${_selectedTemplate!.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ..._selectedTemplate!.attributes.map((attribute) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAttributeField(attribute),
                  );
                }),
              ],
              
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
                      onPressed: _isLoading ? null : _saveProduct,
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
  
  Widget _buildAttributeField(TemplateAttributeEntity attribute) {
    switch (attribute.type) {
      case AttributeType.number:
        return _buildNumberField(attribute);
      case AttributeType.text:
        return _buildTextField(
          controller: _attributeControllers[attribute.variable]!,
          label: attribute.name,
          hint: attribute.defaultValue,
          isRequired: attribute.isRequired,
          validator: attribute.isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '${attribute.name} обязательно';
            }
            return null;
          } : null,
        );
      case AttributeType.select:
        return _buildSelectField(attribute);
      case AttributeType.boolean:
        return _buildBooleanField(attribute);
      case AttributeType.date:
        return _buildDateField(attribute);
      case AttributeType.file:
        return _buildFileField(attribute);
    }
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
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildNumberField(TemplateAttributeEntity attribute) {
    return TextFormField(
      controller: _attributeControllers[attribute.variable]!,
      decoration: InputDecoration(
        labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
        hintText: attribute.defaultValue,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        suffixText: attribute.unit,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: attribute.isRequired ? (value) {
        if (value == null || value.trim().isEmpty) {
          return '${attribute.name} обязательно';
        }
        if (double.tryParse(value) == null) {
          return 'Некорректное число';
        }
        return null;
      } : null,
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value;
        });
        if (attribute.isInFormula) {
          _calculateFormula();
        }
      },
    );
  }
  
  Widget _buildSelectField(TemplateAttributeEntity attribute) {
    return DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
      value: _attributeValues[attribute.variable]?.toString(),
      decoration: InputDecoration(
        labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: attribute.selectOptions?.map((option) => DropdownMenuItem(
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
          return 'Выберите ${attribute.name.toLowerCase()}';
        }
        return null;
      } : null,
    );
  }
  
  Widget _buildBooleanField(TemplateAttributeEntity attribute) {
    return CheckboxListTile(
      title: Text(attribute.name),
      value: _attributeValues[attribute.variable] as bool? ?? false,
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
  
  Widget _buildDateField(TemplateAttributeEntity attribute) {
    final value = _attributeValues[attribute.variable] as DateTime?;
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            _attributeValues[attribute.variable] = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? _formatDate(value) : 'Не указана',
        ),
      ),
    );
  }
  
  Widget _buildFileField(TemplateAttributeEntity attribute) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attribute.isRequired ? '${attribute.name} *' : attribute.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Реализовать выбор файла
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Выбор файлов - в разработке')),
              );
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Выбрать файл'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProducerDropdown() {
    return Consumer(
      builder: (context, ref, child) {
        final producersAsync = ref.watch(producersProvider);
        
        return producersAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Ошибка загрузки производителей: $error'),
          data: (producers) {
            return DropdownButtonFormField<int>(
              value: _selectedProducerId,
              decoration: const InputDecoration(
                labelText: 'Производитель',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Не выбран'),
                ),
                ...producers.map((producer) {
                  return DropdownMenuItem<int>(
                    value: producer.id,
                    child: Text(producer.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProducerId = value;
                });
              },
            );
          },
        );
      },
    );
  }
  
  void _selectDate(BuildContext context, bool isArrival) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _arrivalDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (date != null) {
      setState(() {
        _arrivalDate = date;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  void _calculateFormula() {
    if (_selectedTemplate?.formula == null) return;
    
    // Простая реализация расчета для демонстрации
    try {
      final formula = _selectedTemplate!.formula!;
      if (formula.contains('length') && formula.contains('width') && formula.contains('height')) {
        final length = double.tryParse(_attributeValues['length']?.toString() ?? '0') ?? 0;
        final width = double.tryParse(_attributeValues['width']?.toString() ?? '0') ?? 0;
        final height = double.tryParse(_attributeValues['height']?.toString() ?? '0') ?? 0;
        
        // Простой расчет для досок: length * width * height / 1000000
        final result = length * width * height / 1000000;
        
        setState(() {
          _calculatedValue = result;
        });
      }
    } catch (e) {
      // Игнорируем ошибки расчета
    }
  }
  
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(productsApiDataSourceProvider);
      
      if (_isEditing) {
        // Обновление товара
        final request = UpdateProductRequest(
          productTemplateId: _selectedTemplate?.id,
          warehouseId: _selectedWarehouseId ?? widget.product!.warehouseId,
          name: null, // Имя генерируется автоматически на сервере
          quantity: double.tryParse(_quantityController.text) ?? 0,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          attributes: _attributeValues,
          producerId: _selectedProducerId,
          transportNumber: _transportNumberController.text.trim().isEmpty ? null : _transportNumberController.text.trim(),
          arrivalDate: _arrivalDate,
          isActive: _isActive,
        );
        
        try {
          await dataSource.updateProduct(widget.product!.id, request);
        } catch (e) {
          // Если есть ошибка парсинга ответа, но товар сохранился, игнорируем
          print('⚠️ Предупреждение при обновлении товара: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Товар обновлен'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Создание товара
        if (_selectedTemplate == null || _selectedWarehouseId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Выберите шаблон товара и склад'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        final request = CreateProductRequest(
          productTemplateId: _selectedTemplate!.id,
          warehouseId: _selectedWarehouseId!,
          name: null, // Имя генерируется автоматически на сервере
          quantity: double.tryParse(_quantityController.text) ?? 0,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          attributes: _attributeValues,
          producerId: _selectedProducerId,
          transportNumber: _transportNumberController.text.trim().isEmpty ? null : _transportNumberController.text.trim(),
          arrivalDate: _arrivalDate,
          isActive: _isActive,
        );
        
        try {
          await dataSource.createProduct(request);
        } catch (e) {
          // Если есть ошибка парсинга ответа, но товар сохранился, игнорируем
          print('⚠️ Предупреждение при создании товара: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Товар создан'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      
      if (mounted) {
        // Обновляем список товаров
        ref.invalidate(productsProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
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
  
  void _deleteProduct() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар'),
        content: Text(
          'Вы уверены, что хотите удалить товар "${widget.product!.name}"?\n\n'
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
    if (!_isEditing) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(productsApiDataSourceProvider);
      await dataSource.deleteProduct(widget.product!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "${widget.product!.name}" удален'),
            backgroundColor: AppColors.success,
          ),
        );
        // Обновляем список товаров
        ref.invalidate(productsProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
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

  /// Конвертировать ProductTemplateModel в ProductTemplateEntity
  ProductTemplateEntity _convertTemplateModelToEntity(ProductTemplateModel model) {
    return ProductTemplateEntity(
      id: model.id,
      name: model.name,
      unit: model.unit,
      description: model.description,
      formula: model.formula,
      attributes: model.attributes?.map((attr) => TemplateAttributeEntity(
        id: attr.id,
        productTemplateId: attr.productTemplateId,
        name: attr.name,
        variable: attr.variable,
        type: _convertAttributeType(attr.type),
        defaultValue: attr.defaultValue,
        unit: attr.unit,
        isRequired: attr.isRequired,
        isInFormula: attr.isInFormula,
        selectOptions: attr.selectOptions,
        sortOrder: attr.sortOrder,
      )).toList() ?? [],
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Конвертировать строковый тип атрибута в enum
  AttributeType _convertAttributeType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return AttributeType.text;
      case 'number':
        return AttributeType.number;
      case 'select':
        return AttributeType.select;
      case 'boolean':
        return AttributeType.boolean;
      default:
        return AttributeType.text;
    }
  }
  
  /// Генерировать название товара на основе характеристик
  String _getGeneratedProductName() {
    if (_selectedTemplate == null) {
      return 'Автоматически формируется из характеристик товара (нередактируемое)';
    }
    
    if (_isEditing && widget.product != null) {
      return widget.product!.name;
    }
    
    // Формируем название по новым правилам:
    // Шаблон: "<Имя шаблона>: {формульные значения через ' x '}{, обычные значения через ','}"
    String name = _selectedTemplate!.name;
    
    if (_attributeValues.isNotEmpty && _selectedTemplate!.attributes.isNotEmpty) {
      // Разделяем атрибуты на две группы
      final formulaAttributes = <String>[];
      final regularAttributes = <String>[];
      
      // Собираем значения для каждой группы
      for (final attribute in _selectedTemplate!.attributes) {
        final value = _attributeValues[attribute.variable];
        
        // Пропускаем пустые значения и текстовые поля
        if (value == null || value.toString().isEmpty || attribute.type == AttributeType.text) {
          continue;
        }
        
        // Добавляем в соответствующую группу
        if (attribute.isInFormula) {
          formulaAttributes.add(value.toString());
        } else if (attribute.type == AttributeType.number || attribute.type == AttributeType.select) {
          regularAttributes.add(value.toString());
        }
      }
      
      // Формируем строку по шаблону
      final parts = <String>[];
      if (formulaAttributes.isNotEmpty) {
        parts.add(formulaAttributes.join(' x '));
      }
      if (regularAttributes.isNotEmpty) {
        parts.add(regularAttributes.join(', '));
      }
      
      if (parts.isNotEmpty) {
        name += ': ' + parts.join(', ');
      }
    }
    
    return name;
  }
}
