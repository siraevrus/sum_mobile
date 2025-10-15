import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/acceptance/data/datasources/acceptance_remote_datasource.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/acceptance/data/models/acceptance_model.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/acceptance/presentation/providers/acceptance_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

// Класс для хранения данных формы товара
class AcceptanceFormData {
  final int? productTemplateId;
  final String quantity;
  final String name;
  final String calculatedVolume;
  final Map<String, dynamic> attributes;
  final ProductTemplateModel? template;
  final Map<String, TextEditingController> attributeControllers;

  AcceptanceFormData({
    this.productTemplateId,
    required this.quantity,
    required this.name,
    required this.calculatedVolume,
    required this.attributes,
    this.template,
    required this.attributeControllers,
  });
}

/// Форма создания/редактирования товара приемки
class AcceptanceFormPage extends ConsumerStatefulWidget {
  final AcceptanceModel? product;
  final bool isViewMode;

  const AcceptanceFormPage({
    super.key,
    this.product,
    this.isViewMode = false,
  });

  @override
  ConsumerState<AcceptanceFormPage> createState() => _AcceptanceFormPageState();
}

class _AcceptanceFormPageState extends ConsumerState<AcceptanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _transportNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _calculatedVolumeController = TextEditingController();
  final _notesController = TextEditingController();
  final _shippingLocationController = TextEditingController();
  
  bool _isLoading = false;
  int? _selectedWarehouseId;
  int? _selectedProducerId;
  int? _selectedProductTemplateId;
  DateTime? _selectedArrivalDate;
  DateTime? _selectedShippingDate;
  
  List<WarehouseModel> _warehouses = [];
  List<ProducerModel> _producers = [];
  List<ProductTemplateModel> _productTemplates = [];
  ProductTemplateModel? _selectedTemplate;
  Map<String, TextEditingController> _attributeControllers = {};
  
  // Переменные для множественных товаров
  List<AcceptanceFormData> _products = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _initializeProducts();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _transportNumberController.dispose();
    _nameController.dispose();
    _calculatedVolumeController.dispose();
    _notesController.dispose();
    _shippingLocationController.dispose();
    // Очищаем контроллеры атрибутов
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditing) {
      final product = widget.product!;
      _quantityController.text = product.quantity;
      _transportNumberController.text = product.transportNumber ?? '';
      _nameController.text = product.name ?? '';
      _calculatedVolumeController.text = product.calculatedVolume ?? '';
      _selectedWarehouseId = product.warehouseId;
      _selectedProducerId = product.producerId;
      _selectedProductTemplateId = product.productTemplateId;
      _selectedArrivalDate = product.arrivalDate != null ? DateTime.parse(product.arrivalDate!) : null;
      _shippingLocationController.text = product.shippingLocation ?? '';
      _selectedShippingDate = product.shippingDate != null ? DateTime.parse(product.shippingDate!) : null;
      _notesController.text = product.notes ?? '';

      // Инициализация формы для редактирования товара
    }
  }

  void _initializeProducts() {
    // Инициализируем первый товар
    _products = [
      AcceptanceFormData(
        quantity: '',
        name: '',
        calculatedVolume: '',
        attributes: {},
        attributeControllers: {},
      ),
    ];
  }

  void _addProduct() {
    setState(() {
      _products.add(
        AcceptanceFormData(
          quantity: '',
          name: '',
          calculatedVolume: '',
          attributes: {},
          attributeControllers: {},
        ),
      );
    });
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        // Очищаем контроллеры перед удалением
        for (final controller in _products[index].attributeControllers.values) {
          controller.dispose();
        }
        _products.removeAt(index);
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Загружаем склады
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;

      // Загружаем производителей
      await ref.read(producersProvider.notifier).loadProducers();
      final producersState = ref.read(producersProvider);
      if (producersState.hasValue) {
        // Конвертируем ProducerEntity в ProducerModel
        _producers = (producersState.value ?? []).map((entity) => ProducerModel(
          id: entity.id,
          name: entity.name,
          region: entity.region,
          productsCount: entity.productsCount,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        )).toList();
      }

      // Загружаем шаблоны товаров
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final templatesResponse = await templateDataSource.getProductTemplates();
      _productTemplates = templatesResponse;

      // Если редактируем, загружаем атрибуты выбранного шаблона
      if (_isEditing && _selectedProductTemplateId != null) {
        await _loadTemplateAttributes();
      }

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTemplateAttributes() async {
    if (_selectedProductTemplateId == null) {
      _selectedTemplate = null;
      _clearAttributeControllers();
      return;
    }

    try {
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _selectedTemplate = await templateDataSource.getProductTemplate(_selectedProductTemplateId!);
      
      // Создаем контроллеры для атрибутов
      _clearAttributeControllers();
      for (final attribute in _selectedTemplate!.attributes) {
        _attributeControllers[attribute.variable] = TextEditingController();
        
        // Если редактируем товар, заполняем значения из существующих атрибутов
        if (_isEditing && widget.product != null) {
          final productAttributes = widget.product!.attributes;
          if (productAttributes is Map<String, dynamic>) {
            final value = productAttributes[attribute.variable]?.toString() ?? '';
            _attributeControllers[attribute.variable]!.text = value;
          }
        }
        
        // Добавляем слушатель для автоматического обновления названия и объема
        _attributeControllers[attribute.variable]!.addListener(() => _onAttributeChanged());
      }

      setState(() {});
    } catch (e) {
      _selectedTemplate = null;
      _clearAttributeControllers();
    }
  }

  void _clearAttributeControllers() {
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    _attributeControllers.clear();
  }

  void _calculateNameAndVolume() {
    if (_selectedTemplate == null || _quantityController.text.isEmpty) {
      _nameController.text = '';
      _calculatedVolumeController.text = '';
      return;
    }

    // Формируем наименование
    _nameController.text = _generateProductNameLegacy();

    // Рассчитываем объем по формуле
    _calculatedVolumeController.text = _calculateVolume();
  }

  String _generateProductNameLegacy() {
    if (_selectedTemplate == null) return '';

    final formulaAttributes = <String>[];
    final regularAttributes = <String>[];

    for (final attribute in _selectedTemplate!.attributes) {
      final value = _attributeControllers[attribute.variable]?.text ?? '';
      if (value.isEmpty) continue;

      if (attribute.isInFormula) {
        formulaAttributes.add(value);
      } else if (attribute.type == 'number' || attribute.type == 'select') {
        regularAttributes.add(value);
      }
    }

    final List<String> nameParts = [_selectedTemplate!.name];

    if (formulaAttributes.isNotEmpty) {
      nameParts.add(formulaAttributes.join(' x '));
    }

    if (regularAttributes.isNotEmpty) {
      nameParts.add(regularAttributes.join(', '));
    }

    return nameParts.join(': ');
  }


  String _calculateVolume() {
    if (_selectedTemplate == null || 
        _selectedTemplate!.formula == null || 
        _quantityController.text.isEmpty) {
      return '0';
    }

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      
      // Заменяем переменные в формуле значениями атрибутов
      String formula = _selectedTemplate!.formula!;
      
      // Заменяем quantity
      formula = formula.replaceAll('quantity', quantity.toString());
      
      // Заменяем атрибуты
      for (final attribute in _selectedTemplate!.attributes) {
        final value = _attributeControllers[attribute.variable]?.text ?? '0';
        final numValue = double.tryParse(value) ?? 0;
        
        // Заменяем переменную на значение
        formula = formula.replaceAll(attribute.variable, numValue.toString());
      }
      
      
      // Простой парсер математических выражений
      final result = _evaluateFormula(formula);
      
      return result.toStringAsFixed(3);
    } catch (e) {
      return '0';
    }
  }

  double _evaluateFormula(String formula) {
    // Простая реализация для базовых математических операций
    // В реальном проекте используйте библиотеку типа math_expressions
    try {
      // Убираем скобки и заменяем операции
      formula = formula.replaceAll('(', '').replaceAll(')', '');
      
      // Разбиваем по операциям
      final parts = formula.split('*');
      double result = 1;
      
      for (final part in parts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isNotEmpty) {
          result *= double.tryParse(trimmedPart) ?? 1;
        }
      }
      
      return result;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Редактирование товара приемки' : 'Создание товара приемки'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        ),
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование товара' : 'Создание товара'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
          ),
        ],
      ),
      body: Form(
      key: _formKey,
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Блок "Основная информация"
              _buildSection(
                title: 'Основная информация',
                children: [
                  // 1. Склад (выпадающее поле)
                  _buildWarehouseDropdown(),
            const SizedBox(height: 16),

                  // 2. Производитель (выпадающее поле)
                  _buildProducerDropdown(),
            const SizedBox(height: 16),

                  // 3. Дата поступления
                  _buildDateField(
                    label: 'Дата поступления',
                    selectedDate: _selectedArrivalDate,
                    onDateSelected: (date) {
                setState(() {
                        _selectedArrivalDate = date;
                      });
              },
            ),
            const SizedBox(height: 16),
            
                  // 4. Номер транспортного средства
            _buildTextField(
              controller: _transportNumberController,
              label: 'Номер транспортного средства',
            ),
            const SizedBox(height: 16),

                  // 5. Место отгрузки
            _buildTextField(
              controller: _shippingLocationController,
                    label: 'Место отгрузки *',
                    isRequired: true,
            ),
            const SizedBox(height: 16),

                  // 6. Дата отгрузки
            _buildDateField(
                    label: 'Дата отгрузки *',
                    selectedDate: _selectedShippingDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedShippingDate = date;
                      });
                    },
                    isRequired: true,
                  ),
                ],
              ),

            const SizedBox(height: 24),

              // Блок "Товары"
              _buildSection(
                title: 'Товары',
                children: [
                  // Список товаров
                  ..._buildProductsList(),
                  
                  // Кнопка добавления товара
            const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить товар'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Блок "Дополнительная информация"
              _buildSection(
                title: 'Дополнительная информация',
                children: [
                  // Поле Заметки
                  _buildNotesField(),
                ],
              ),

            const SizedBox(height: 24),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEditing ? _updateProduct : _createProduct,
                      child: Text(_isEditing ? 'Обновить' : 'Создать'),
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
      title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hintText,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Поле обязательно для заполнения';
                  }
                  return null;
      },
    );
  }


  Widget _buildProductTemplateDropdown(int index) {
    final product = _products[index];
    
          return DropdownButtonFormField<int>(
      value: product.productTemplateId,
      decoration: InputDecoration(
              labelText: 'Шаблон товара *',
        border: const OutlineInputBorder(),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
            ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Выберите шаблон товара')),
        ..._productTemplates.map((template) => DropdownMenuItem(
                value: template.id,
                child: Text(template.name),
        )),
      ],
            onChanged: widget.isViewMode ? null : (value) {
        _onProductTemplateChanged(index, value);
            },
            validator: (value) {
              if (value == null) {
          return 'Выберите шаблон товара';
              }
              return null;
            },
          );
        }

  Widget _buildQuantityField(int index) {
    final product = _products[index];
    
    return TextFormField(
      controller: TextEditingController(text: product.quantity),
      decoration: InputDecoration(
        labelText: 'Количество *',
        border: const OutlineInputBorder(),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      keyboardType: TextInputType.number,
      readOnly: widget.isViewMode,
      onChanged: (value) {
        _onProductQuantityChanged(index, value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите количество';
        }
        if (double.tryParse(value) == null) {
          return 'Введите корректное число';
        }
        return null;
      },
    );
  }

  Widget _buildNameField(int index) {
    final product = _products[index];
    
    return TextFormField(
      controller: TextEditingController(text: product.name),
      decoration: InputDecoration(
        labelText: 'Наименование',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: 'Формируется автоматически',
      ),
      readOnly: true,
    );
  }

  Widget _buildVolumeField(int index) {
    final product = _products[index];
    
    return TextFormField(
      controller: TextEditingController(text: product.calculatedVolume),
      decoration: InputDecoration(
        labelText: 'Рассчитанный объем',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: 'Рассчитывается по формуле',
      ),
      readOnly: true,
    );
  }

  Widget _buildWarehouseDropdown() {
          return DropdownButtonFormField<int>(
            value: _selectedWarehouseId,
      decoration: InputDecoration(
        labelText: 'Склад *',
        border: const OutlineInputBorder(),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Выберите склад')),
        ..._warehouses.map((warehouse) => DropdownMenuItem(
                value: warehouse.id,
                child: Text(warehouse.name),
        )),
      ],
            onChanged: widget.isViewMode ? null : (value) {
              setState(() {
                _selectedWarehouseId = value;
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

  Widget _buildProducerDropdown() {
    return DropdownButtonFormField<int>(
            value: _selectedProducerId,
      decoration: InputDecoration(
              labelText: 'Производитель',
        border: const OutlineInputBorder(),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
            ),
            items: [
        const DropdownMenuItem(value: null, child: Text('Выберите производителя')),
        ..._producers.map((producer) => DropdownMenuItem(
                  value: producer.id,
                  child: Text(producer.name),
        )),
            ],
            onChanged: widget.isViewMode ? null : (value) {
              setState(() {
                _selectedProducerId = value;
              });
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
    bool isRequired = false,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate) : '',
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: widget.isViewMode ? null : const Icon(Icons.calendar_today),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      onTap: widget.isViewMode
          ? null
          : () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              onDateSelected(picked);
            },
      validator: (value) {
        if (isRequired && (selectedDate == null || selectedDate.toString().isEmpty)) {
          return 'Выберите дату';
        }
        return null;
      },
    );
  }

  List<Widget> _buildProductsList() {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < _products.length; i++) {
      widgets.add(_buildProductCard(i));
      if (i < _products.length - 1) {
        widgets.add(const SizedBox(height: 24));
      }
    }
    
    return widgets;
  }

  Widget _buildProductCard(int index) {
    final product = _products[index];
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Заголовок товара с кнопкой удаления
          Row(
            children: [
                Text(
                  'Товар ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_products.length > 1)
                  IconButton(
                    onPressed: () => _removeProduct(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Удалить товар',
              ),
            ],
          ),
            const SizedBox(height: 16),
            
            // Поля товара
            _buildProductTemplateDropdown(index),
            const SizedBox(height: 16),
            
            _buildQuantityField(index),
            const SizedBox(height: 16),
            
            // Динамические поля атрибутов
            ..._buildAttributeFieldsForProduct(index),
            
            const SizedBox(height: 16),
            
            // Поле Наименование (автоматически формируется)
            _buildNameField(index),
            const SizedBox(height: 16),
            
            // Рассчитанный объем (автоматически считается)
            _buildVolumeField(index),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttributeFields() {
    if (_selectedTemplate == null) return [];

    final List<Widget> fields = [];
    
    for (final attribute in _selectedTemplate!.attributes) {
      final controller = _attributeControllers[attribute.variable];
      if (controller == null) continue;

      fields.add(
        _buildAttributeField(attribute, controller),
      );
      fields.add(const SizedBox(height: 16));
    }

    return fields;
  }

  List<Widget> _buildAttributeFieldsForProduct(int index) {
    final product = _products[index];
    if (product.template == null) return [];

    final List<Widget> fields = [];
    
    for (final attribute in product.template!.attributes) {
      final controller = product.attributeControllers[attribute.variable];
      if (controller == null) continue;

      fields.add(
        _buildAttributeField(attribute, controller),
      );
      fields.add(const SizedBox(height: 16));
    }

    return fields;
  }

  Widget _buildAttributeField(ProductAttributeModel attribute, TextEditingController controller) {
    Widget field;

    switch (attribute.type) {
      case 'number':
        field = _buildTextField(
          controller: controller,
          label: attribute.name + (attribute.isRequired ? ' *' : ''),
          isRequired: attribute.isRequired,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hintText: attribute.unit != null ? 'в ${attribute.unit}' : null,
        );
            break;
      case 'select':
        field = _buildSelectField(attribute, controller);
            break;
      default:
        field = _buildTextField(
          controller: controller,
          label: attribute.name + (attribute.isRequired ? ' *' : ''),
          isRequired: attribute.isRequired,
        );
    }

    return field;
  }

  Widget _buildSelectField(ProductAttributeModel attribute, TextEditingController controller) {
    List<String> options = [];
    
    if (attribute.options is String) {
      try {
        final decoded = json.decode(attribute.options as String) as List;
        options = decoded.cast<String>();
      } catch (e) {
        options = [];
      }
    } else if (attribute.options is List) {
      options = (attribute.options as List).cast<String>();
    }

    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      decoration: InputDecoration(
        labelText: '${attribute.name}${attribute.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Выберите значение')),
        ...options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )),
      ],
      onChanged: widget.isViewMode ? null : (value) {
        controller.text = value ?? '';
        _onAttributeChanged();
      },
      validator: attribute.isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите значение';
        }
        return null;
      } : null,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Заметки',
        hintText: 'Введите дополнительные заметки (до 5000 символов)',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      maxLines: 6,
      maxLength: 5000,
      readOnly: widget.isViewMode,
    );
  }

  void _onQuantityChanged() {
    _calculateNameAndVolume();
  }

  void _onTemplateChanged() {
    _loadTemplateAttributes();
    _calculateNameAndVolume();
  }

  void _onAttributeChanged() {
    _calculateNameAndVolume();
  }

  void _onProductTemplateChanged(int index, int? templateId) {
        setState(() {
      _products[index] = AcceptanceFormData(
        productTemplateId: templateId,
        quantity: _products[index].quantity,
        name: _products[index].name,
        calculatedVolume: _products[index].calculatedVolume,
        attributes: _products[index].attributes,
        template: templateId != null ? _productTemplates.firstWhere((t) => t.id == templateId) : null,
        attributeControllers: _products[index].attributeControllers,
      );
    });
    
    if (templateId != null) {
      _loadProductTemplateAttributes(index, templateId);
    }
  }

  void _onProductQuantityChanged(int index, String quantity) {
    setState(() {
      _products[index] = AcceptanceFormData(
        productTemplateId: _products[index].productTemplateId,
        quantity: quantity,
        name: _products[index].name,
        calculatedVolume: _products[index].calculatedVolume,
        attributes: _products[index].attributes,
        template: _products[index].template,
        attributeControllers: _products[index].attributeControllers,
      );
    });
    
    _calculateProductNameAndVolume(index);
  }

  Future<void> _loadProductTemplateAttributes(int index, int templateId) async {
    try {
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final template = await templateDataSource.getProductTemplate(templateId);
      
      // Очищаем старые контроллеры
      for (final controller in _products[index].attributeControllers.values) {
        controller.dispose();
      }
      
      final newAttributeControllers = <String, TextEditingController>{};
      
      // Создаем контроллеры для атрибутов
      for (final attribute in template.attributes) {
        newAttributeControllers[attribute.variable] = TextEditingController();
      }
      
        setState(() {
        _products[index] = AcceptanceFormData(
          productTemplateId: templateId,
          quantity: _products[index].quantity,
          name: _products[index].name,
          calculatedVolume: _products[index].calculatedVolume,
          attributes: _products[index].attributes,
          template: template,
          attributeControllers: newAttributeControllers,
        );
      });
      
      _calculateProductNameAndVolume(index);
    } catch (e) {
    }
  }

  void _calculateProductNameAndVolume(int index) {
    final product = _products[index];
    if (product.template == null || product.quantity.isEmpty) {
        setState(() {
        _products[index] = AcceptanceFormData(
          productTemplateId: product.productTemplateId,
          quantity: product.quantity,
          name: '',
          calculatedVolume: '',
          attributes: product.attributes,
          template: product.template,
          attributeControllers: product.attributeControllers,
        );
        });
        return;
      }
      
    // Формируем наименование
    final name = _generateProductName(index);
    
    // Рассчитываем объем по формуле
    final volume = _calculateProductVolume(index);

      setState(() {
      _products[index] = AcceptanceFormData(
        productTemplateId: product.productTemplateId,
        quantity: product.quantity,
        name: name,
        calculatedVolume: volume,
        attributes: product.attributes,
        template: product.template,
        attributeControllers: product.attributeControllers,
      );
    });
  }

  String _generateProductName(int index) {
    final product = _products[index];
    if (product.template == null) return '';

    final formulaAttributes = <String>[];
    final regularAttributes = <String>[];

    for (final attribute in product.template!.attributes) {
      final value = product.attributeControllers[attribute.variable]?.text ?? '';
      if (value.isEmpty) continue;

      if (attribute.isInFormula) {
        formulaAttributes.add(value);
      } else if (attribute.type == 'number' || attribute.type == 'select') {
        regularAttributes.add(value);
      }
    }

    final List<String> nameParts = [product.template!.name];

    if (formulaAttributes.isNotEmpty) {
      nameParts.add(formulaAttributes.join(' x '));
    }

    if (regularAttributes.isNotEmpty) {
      nameParts.add(regularAttributes.join(', '));
    }

    return nameParts.join(': ');
  }

  String _calculateProductVolume(int index) {
    final product = _products[index];
    if (product.template == null || 
        product.template!.formula == null || 
        product.quantity.isEmpty) {
      return '0';
    }

    try {
      final quantity = double.tryParse(product.quantity) ?? 0;
      
      // Заменяем переменные в формуле значениями атрибутов
      String formula = product.template!.formula!;
      
      // Заменяем quantity
      formula = formula.replaceAll('quantity', quantity.toString());
      
      // Заменяем атрибуты
      for (final attribute in product.template!.attributes) {
        final value = product.attributeControllers[attribute.variable]?.text ?? '0';
        final numValue = double.tryParse(value) ?? 0;
        
        // Заменяем переменную на значение
        formula = formula.replaceAll(attribute.variable, numValue.toString());
      }
      
      
      // Простой парсер математических выражений
      final result = _evaluateFormula(formula);
      
      return result.toStringAsFixed(3);
    } catch (e) {
      return '0';
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      
      final provider = ref.read(acceptanceNotifierProvider.notifier);
      
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          attributes[entry.key] = entry.value.text;
        }
      }

      final request = CreateAcceptanceRequest(
        warehouseId: _selectedWarehouseId!,
        producerId: _selectedProducerId,
        productTemplateId: _selectedProductTemplateId!,
        quantity: _quantityController.text,
        name: _nameController.text,
        calculatedVolume: _calculatedVolumeController.text,
        attributes: attributes,
        transportNumber: _transportNumberController.text.isNotEmpty ? _transportNumberController.text : null,
        arrivalDate: _selectedArrivalDate?.toIso8601String(),
        shippingLocation: _shippingLocationController.text.isNotEmpty ? _shippingLocationController.text : null,
        shippingDate: _selectedShippingDate?.toIso8601String(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await provider.createProduct(request);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      
      final provider = ref.read(acceptanceNotifierProvider.notifier);
      
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          attributes[entry.key] = entry.value.text;
        }
      }

      final request = UpdateAcceptanceRequest(
        producerId: _selectedProducerId,
        quantity: _quantityController.text,
        name: _nameController.text,
        calculatedVolume: _calculatedVolumeController.text,
        attributes: attributes,
        transportNumber: _transportNumberController.text.isNotEmpty ? _transportNumberController.text : null,
        arrivalDate: _selectedArrivalDate?.toIso8601String(),
        shippingLocation: _shippingLocationController.text.isNotEmpty ? _shippingLocationController.text : null,
        shippingDate: _selectedShippingDate?.toIso8601String(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await provider.updateProduct(widget.product!.id!, request);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
