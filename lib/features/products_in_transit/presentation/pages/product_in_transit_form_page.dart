import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/shared/providers/app_data_provider.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';


/// Страница создания/редактирования товара в пути
class ProductInTransitFormPage extends ConsumerStatefulWidget {
  final ProductModel? product;
  final bool isViewMode;

  const ProductInTransitFormPage({
    super.key,
    this.product,
    this.isViewMode = false,
  });

  @override
  ConsumerState<ProductInTransitFormPage> createState() => _ProductInTransitFormPageState();
}

class _ProductInTransitFormPageState extends ConsumerState<ProductInTransitFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Обязательные поля
  final _quantityController = TextEditingController();
  int? _selectedProductTemplateId;
  int? _selectedWarehouseId;
  
  // Необязательные поля
  final _nameController = TextEditingController();
  final _transportNumberController = TextEditingController();
  final _shippingLocationController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedProducerId;
  DateTime? _selectedArrivalDate;
  DateTime? _selectedShippingDate;
  DateTime? _selectedExpectedArrivalDate;
  bool _isActive = true;
  bool _isLoading = false;
  
  // Для хранения выбранного шаблона и его характеристик
  ProductTemplateModel? _selectedTemplate;
  List<TemplateAttributeModel> _templateAttributes = [];
  Map<String, TextEditingController> _attributeControllers = {};
  Map<String, dynamic> _attributeValues = {};

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    
    // Инициализируем загрузку производителей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(producersProvider.notifier).loadProducers();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _nameController.dispose();
    _transportNumberController.dispose();
    _shippingLocationController.dispose();
    _notesController.dispose();
    
    // Освобождаем контроллеры атрибутов
    for (var controller in _attributeControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditing) {
      final product = widget.product!;
      _quantityController.text = product.quantity.toString();
      _selectedProductTemplateId = product.productTemplateId;
      _selectedWarehouseId = product.warehouseId;
      _nameController.text = product.name;
      _transportNumberController.text = product.transportNumber ?? '';
      _shippingLocationController.text = product.shippingLocation ?? '';
      _notesController.text = product.notes ?? '';
      _selectedProducerId = product.producerId;
      _selectedArrivalDate = product.arrivalDate;
      _selectedShippingDate = product.shippingDate;
      _selectedExpectedArrivalDate = product.expectedArrivalDate;
      _isActive = product.isActive;
      
      // Загружаем атрибуты шаблона для редактирования
      if (product.productTemplateId != null) {
        print('🔵 Загружаем атрибуты для редактирования товара, шаблон ID: ${product.productTemplateId}');
        _loadTemplateAttributesFromAPI(product.productTemplateId!);
      }
    }
  }

  void _onTemplateSelected(ProductTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
      // Генерируем название товара с учетом характеристик
      _nameController.text = _generateProductName();
    });
    
    // Загружаем атрибуты шаблона из API
    _loadTemplateAttributesFromAPI(template.id);
  }

  /// Загрузка атрибутов шаблона из API
  Future<void> _loadTemplateAttributesFromAPI(int templateId) async {
    try {
      print('🔵 Загружаем атрибуты шаблона $templateId из API...');
      
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final attributes = await dataSource.getTemplateAttributes(templateId);
      
      print('🔵 Получено ${attributes.length} атрибутов из API');
      
      setState(() {
        _loadTemplateAttributesFromList(attributes);
      });
    } catch (e, stackTrace) {
      print('🔴 Ошибка загрузки атрибутов шаблона: $e');
      print('🔴 Stack trace: $stackTrace');
      
      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки характеристик: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _loadTemplateAttributesFromList(List<TemplateAttributeModel> attributes) {
    // Очищаем предыдущие контроллеры
    for (var controller in _attributeControllers.values) {
      controller.dispose();
    }
    _attributeControllers.clear();
    _attributeValues.clear();

    // Сохраняем загруженные атрибуты
    _templateAttributes = attributes;
    
    print('🔵 Обрабатываем ${_templateAttributes.length} атрибутов');
    
    for (var attribute in _templateAttributes) {
      print('🔵 Атрибут: ${attribute.name} (тип: ${attribute.type}, обязательный: ${attribute.isRequired})');
      
      final controller = TextEditingController();
      
      // Устанавливаем значение по умолчанию
      String initialValue = '';
      if (attribute.defaultValue != null && attribute.defaultValue!.isNotEmpty) {
        initialValue = attribute.defaultValue!;
      }
      
      // Если редактируем существующий товар, заполняем значения
      if (_isEditing && widget.product?.attributes != null) {
        final existingValue = widget.product!.attributes![attribute.variable];
        if (existingValue != null) {
          initialValue = existingValue.toString();
        }
      }
      
      controller.text = initialValue;
      _attributeControllers[attribute.variable] = controller;
      _attributeValues[attribute.variable] = initialValue;
    }
    
    print('🔵 Созданы контроллеры для ${_attributeControllers.length} атрибутов');
    
    // Обновляем название товара после загрузки атрибутов
    setState(() {
      _nameController.text = _generateProductName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewMode
              ? 'Просмотр товара в пути'
              : _isEditing
                  ? 'Редактировать товар в пути'
                  : 'Новый товар в пути',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: widget.isViewMode ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Переходим в режим редактирования
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductInTransitFormPage(
                    product: widget.product,
                    isViewMode: false,
                  ),
                ),
              );
            },
            tooltip: 'Редактировать',
          ),
        ] : null,
      ),
      body: widget.isViewMode ? _buildViewMode() : _buildEditMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewItem('Наименование', widget.product?.name ?? 'Не указано'),
          _buildViewItem('Количество', widget.product?.quantity.toString() ?? 'Не указано'),
          if (widget.product?.producerInfo?.name != null)
            _buildViewItem('Производитель', widget.product!.producerInfo!.name!),
          if (widget.product?.warehouse?.name != null)
            _buildViewItem('Склад назначения', widget.product!.warehouse!.name!),
          if (widget.product?.transportNumber != null && widget.product!.transportNumber!.isNotEmpty)
            _buildViewItem('Номер транспортного средства', widget.product!.transportNumber!),
          if (widget.product?.shippingLocation != null && widget.product!.shippingLocation!.isNotEmpty)
            _buildViewItem('Место отправки', widget.product!.shippingLocation!),
          if (widget.product?.calculatedVolume != null)
            _buildViewItem('Объем', '${widget.product!.calculatedVolume!.toStringAsFixed(2)} м³'),
          if (widget.product?.shippingDate != null)
            _buildViewItem('Дата отправки', _formatDate(widget.product!.shippingDate!)),
          if (widget.product?.expectedArrivalDate != null)
            _buildViewItem('Ожидаемая дата прибытия', _formatDate(widget.product!.expectedArrivalDate!)),
          if (widget.product?.notes != null && widget.product!.notes!.isNotEmpty)
            _buildViewItem('Заметки', widget.product!.notes!),
          
          // Показываем атрибуты товара
          if (widget.product?.attributes != null && widget.product!.attributes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Характеристики:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.product!.attributes!.entries.map((entry) {
              // Ищем соответствующий атрибут по variable, чтобы получить name
              final attribute = _templateAttributes.firstWhere(
                (attr) => attr.variable == entry.key,
                orElse: () => TemplateAttributeModel(
                  id: 0,
                  productTemplateId: 0,
                  name: entry.key, // Fallback к variable если не найден
                  variable: entry.key,
                  type: 'text',
                  isRequired: false,
                ),
              );
              return _buildViewItem(attribute.name, entry.value.toString());
            }),
          ],
          
          _buildViewItem('Статус', widget.product?.isActive == true ? 'Активный' : 'Неактивный'),
        ],
      ),
    );
  }

  Widget _buildViewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF6C757D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Обязательные поля
            _buildSectionTitle('Обязательные поля'),
            const SizedBox(height: 16),

            _buildProductTemplateDropdown(),
            const SizedBox(height: 16),

            _buildWarehouseDropdown(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _quantityController,
              label: 'Количество',
              hint: '100',
              keyboardType: TextInputType.number,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Количество обязательно';
                }
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Введите корректное количество';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Наименование
            _buildSectionTitle('Наименование'),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nameController,
              label: 'Название товара',
              hint: 'Генерируется автоматически по шаблону',
              enabled: false, // Поле нередактируемое
            ),
            const SizedBox(height: 16),

            // Характеристики шаблона
            if (_templateAttributes.isNotEmpty) ...[
              _buildSectionTitle('Характеристики'),
              const SizedBox(height: 16),
              ..._templateAttributes.map((attribute) => Column(
                children: [
                  _buildAttributeField(attribute),
                  const SizedBox(height: 16),
                ],
              )).toList(),
            ],


            _buildProducerDropdown(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _transportNumberController,
              label: 'Номер транспортного средства',
              hint: 'А123БВ777',
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _shippingLocationController,
              label: 'Место отправки',
              hint: 'Москва, ул. Ленина, д. 1',
            ),
            const SizedBox(height: 16),

            _buildDateField(
              label: 'Дата отправки',
              value: _selectedShippingDate,
              onTap: () => _selectDate(context, 'shipping'),
            ),
            const SizedBox(height: 16),

            _buildDateField(
              label: 'Ожидаемая дата прибытия',
              value: _selectedExpectedArrivalDate,
              onTap: () => _selectDate(context, 'expected_arrival'),
            ),
            const SizedBox(height: 16),

            // Удаляем поле "Дата прибытия"

            _buildTextField(
              controller: _notesController,
              label: 'Заметки',
              hint: 'Дополнительная информация',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Статус
            _buildSectionTitle('Статус'),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Активный'),
              subtitle: const Text('Неактивные товары скрыты из списков'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Кнопки действий
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildAttributeField(TemplateAttributeModel attribute) {
    final controller = _attributeControllers[attribute.variable]!;
    
    // Определяем тип поля по типу атрибута
    switch (attribute.type) {
      case 'select':
        // Выпадающий список
        return _buildSelectField(attribute, controller);
      case 'number':
      case 'decimal':
        // Числовое поле
        return _buildTextField(
          controller: controller,
          label: attribute.name + (attribute.unit != null ? ' (${attribute.unit})' : ''),
          hint: attribute.defaultValue ?? 'Введите ${attribute.name.toLowerCase()}',
          keyboardType: TextInputType.number,
          isRequired: attribute.isRequired,
          onChanged: (value) {
            _attributeValues[attribute.variable] = value;
            // Обновляем название товара при изменении характеристик
            _nameController.text = _generateProductName();
          },
          validator: (value) {
            if (attribute.isRequired && (value == null || value.trim().isEmpty)) {
              return '${attribute.name} обязателен';
            }
            if (value != null && value.isNotEmpty) {
              final numValue = double.tryParse(value);
              if (numValue == null) {
                return 'Введите корректное число';
              }
              if (attribute.minValue != null && numValue < attribute.minValue!) {
                return 'Минимальное значение: ${attribute.minValue}';
              }
              if (attribute.maxValue != null && numValue > attribute.maxValue!) {
                return 'Максимальное значение: ${attribute.maxValue}';
              }
            }
            return null;
          },
        );
      case 'text':
      case 'string':
      default:
        // Текстовое поле
        return _buildTextField(
          controller: controller,
          label: attribute.name + (attribute.unit != null ? ' (${attribute.unit})' : ''),
          hint: attribute.defaultValue ?? 'Введите ${attribute.name.toLowerCase()}',
          isRequired: attribute.isRequired,
          onChanged: (value) {
            _attributeValues[attribute.variable] = value;
            // Обновляем название товара при изменении характеристик
            _nameController.text = _generateProductName();
          },
          validator: (value) {
            if (attribute.isRequired && (value == null || value.trim().isEmpty)) {
              return '${attribute.name} обязателен';
            }
            return null;
          },
        );
    }
  }

  Widget _buildSelectField(TemplateAttributeModel attribute, TextEditingController controller) {
    // Получаем опции для выбора
    List<String> options = [];
    if (attribute.selectOptions != null && attribute.selectOptions!.isNotEmpty) {
      options = attribute.selectOptions!;
    } else {
      // Пытаемся парсить опции из других полей
      if (attribute.options != null) {
        options = _parseSelectOptions(attribute.options) ?? [];
      } else if (attribute.value != null) {
        options = _parseSelectOptions(attribute.value) ?? [];
      }
    }

    if (options.isEmpty) {
      // Если нет опций, показываем обычное текстовое поле
      return _buildTextField(
        controller: controller,
        label: attribute.name,
        hint: attribute.defaultValue ?? 'Введите ${attribute.name.toLowerCase()}',
        isRequired: attribute.isRequired,
        onChanged: (value) {
          _attributeValues[attribute.variable] = value;
          // Обновляем название товара при изменении характеристик
          _nameController.text = _generateProductName();
        },
      );
    }

    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      decoration: InputDecoration(
        labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (!attribute.isRequired)
          const DropdownMenuItem<String>(
            value: '',
            child: Text('Не выбрано'),
          ),
        ...options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ],
      onChanged: (value) {
        controller.text = value ?? '';
        _attributeValues[attribute.variable] = value ?? '';
        // Обновляем название товара при изменении характеристик
        _nameController.text = _generateProductName();
      },
      validator: attribute.isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return '${attribute.name} обязателен';
        }
        return null;
      } : null,
    );
  }

  /// Парсинг опций для select атрибутов
  List<String>? _parseSelectOptions(dynamic value) {
    if (value == null) return null;
    
    // Если это уже список строк
    if (value is List<String>) return value;
    
    // Если это список с любыми типами, конвертируем в строки
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    
    // Если это строка с разделителями
    if (value is String && value.isNotEmpty) {
      String cleanValue = value.trim();
      if (cleanValue.endsWith('.')) {
        cleanValue = cleanValue.substring(0, cleanValue.length - 1);
      }
      
      return cleanValue
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label обязателен';
                  }
                  return null;
                }
              : null),
    );
  }

  Widget _buildProductTemplateDropdown() {
    return FutureBuilder(
      future: ref.watch(allProductTemplatesProvider.future),
      builder: (context, AsyncSnapshot<List<ProductTemplateModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Ошибка: ${snapshot.error}');
        } else {
          final templates = snapshot.data ?? [];
          return DropdownButtonFormField<int>(
            value: _selectedProductTemplateId,
            decoration: const InputDecoration(
              labelText: 'Шаблон товара *',
              border: OutlineInputBorder(),
            ),
            items: templates.map((template) {
              return DropdownMenuItem<int>(
                value: template.id,
                child: Text('${template.name} (${template.unit})'),
              );
            }).toList(),
            onChanged: widget.isViewMode ? null : (value) {
              if (value != null) {
                final templates = snapshot.data ?? [];
                final template = templates.firstWhere((t) => t.id == value);
                setState(() {
                  _selectedProductTemplateId = value;
                });
                _onTemplateSelected(template);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Шаблон товара обязателен';
              }
              return null;
            },
          );
        }
      },
    );
  }

  Widget _buildWarehouseDropdown() {
    return FutureBuilder(
      future: ref.watch(warehousesProvider.future),
      builder: (context, AsyncSnapshot<List<WarehouseModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Ошибка: ${snapshot.error}');
        } else {
          final warehouses = snapshot.data ?? [];
          return DropdownButtonFormField<int>(
            value: _selectedWarehouseId,
            decoration: const InputDecoration(
              labelText: 'Склад назначения *',
              border: OutlineInputBorder(),
            ),
            items: warehouses.map((warehouse) {
              return DropdownMenuItem<int>(
                value: warehouse.id,
                child: Text(warehouse.name),
              );
            }).toList(),
            onChanged: widget.isViewMode ? null : (value) {
              setState(() {
                _selectedWarehouseId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Склад назначения обязателен';
              }
              return null;
            },
          );
        }
      },
    );
  }

  Widget _buildProducerDropdown() {
    return Consumer(
      builder: (context, ref, child) {
        final producersAsync = ref.watch(producersProvider);
        
        return producersAsync.when(
          loading: () => DropdownButtonFormField<int>(
            value: null,
            decoration: const InputDecoration(
              labelText: 'Производитель (загрузка...)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<int>(
                value: null,
                child: Text('Загрузка...'),
              ),
            ],
            onChanged: null,
          ),
          error: (error, stack) => DropdownButtonFormField<int>(
            value: null,
            decoration: const InputDecoration(
              labelText: 'Производитель (ошибка)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<int>(
                value: null,
                child: Text('Ошибка загрузки'),
              ),
            ],
            onChanged: null,
          ),
          data: (producers) => DropdownButtonFormField<int>(
            value: _selectedProducerId,
            decoration: const InputDecoration(
              labelText: 'Производитель',
              border: OutlineInputBorder(),
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
              }),
            ],
            onChanged: widget.isViewMode ? null : (value) {
              setState(() {
                _selectedProducerId = value;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
              : 'Не выбрана',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_isEditing) {
      // Режим редактирования - три кнопки
      return Column(
        children: [
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
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _deleteProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Удалить'),
            ),
          ),
        ],
      );
    } else {
      // Режим создания - две кнопки
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
                  : const Text('Создать'),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'shipping':
            _selectedShippingDate = picked;
            break;
          case 'expected_arrival':
            _selectedExpectedArrivalDate = picked;
            break;
          case 'arrival':
            _selectedArrivalDate = picked;
            break;
        }
      });
    }
  }

  void _deleteProduct() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар'),
        content: const Text('Вы уверены, что хотите удалить этот товар? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Удаляем товар через API
        await ref
            .read(productsInTransitProvider.notifier)
            .deleteProductInTransit(widget.product!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${widget.product!.name}" удален'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Закрываем форму
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = double.parse(_quantityController.text);
      
      if (_isEditing) {
        // Обновление существующего товара
        final request = UpdateProductRequest(
          productTemplateId: _selectedProductTemplateId,
          warehouseId: _selectedWarehouseId,
          quantity: quantity,
          name: _nameController.text.isEmpty ? null : _nameController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          producerId: _selectedProducerId,
          transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
          arrivalDate: _selectedArrivalDate,
          shippingLocation: _shippingLocationController.text.isEmpty ? null : _shippingLocationController.text,
          attributes: _attributeValues.isNotEmpty ? _attributeValues : {},
          shippingDate: _selectedShippingDate,
          expectedArrivalDate: _selectedExpectedArrivalDate,
          isActive: _isActive,
          status: 'for_receipt',
        );

        final result = await ref
            .read(productsInTransitProvider.notifier)
            .updateProductInTransit(widget.product!.id, request);

        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${result.name}" обновлен'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Создание нового товара
        final request = CreateProductRequest(
          productTemplateId: _selectedProductTemplateId!,
          warehouseId: _selectedWarehouseId!,
          quantity: quantity,
          name: _nameController.text.isEmpty ? null : _nameController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          producerId: _selectedProducerId,
          transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
          arrivalDate: _selectedArrivalDate,
          shippingLocation: _shippingLocationController.text.isEmpty ? null : _shippingLocationController.text,
          attributes: _attributeValues.isNotEmpty ? _attributeValues : {},
          shippingDate: _selectedShippingDate,
          expectedArrivalDate: _selectedExpectedArrivalDate,
          isActive: _isActive,
          status: 'for_receipt',
        );

        final result = await ref
            .read(productsInTransitProvider.notifier)
            .createProductInTransit(request);

        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${result.name}" создан'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
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

  /// Генерировать название товара на основе характеристик
  String _generateProductName() {
    if (_selectedTemplate == null) {
      return 'Выберите шаблон товара';
    }
    
    // Начинаем с названия шаблона
    String name = _selectedTemplate!.name;
    
    if (_attributeValues.isNotEmpty && _templateAttributes.isNotEmpty) {
      // Разделяем атрибуты по типу
      final formulaAttributes = <String>[]; // только number
      final regularAttributes = <String>[]; // только select
      
      // Собираем значения для каждой группы
      for (final attribute in _templateAttributes) {
        final value = _attributeValues[attribute.variable];
        
        // Пропускаем пустые значения
        if (value == null || value.toString().isEmpty) {
          continue;
        }
        
        // Классифицируем по типу атрибута
        switch (attribute.type.toLowerCase()) {
          case 'number':
          case 'decimal':
            // Формульные значения (number)
            formulaAttributes.add(value.toString());
            break;
          case 'select':
            // Обычные значения (select)
            regularAttributes.add(value.toString());
            break;
          case 'text':
          case 'string':
          default:
            // Текстовые поля игнорируем полностью
            break;
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
