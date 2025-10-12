import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

// Класс для хранения данных формы товара
class ProductFormData {
  final int? productTemplateId;
  final String quantity;
  final String name;
  final String calculatedVolume;
  final Map<String, dynamic> attributes;
  final ProductTemplateModel? template;
  final Map<String, TextEditingController> attributeControllers;
  final TextEditingController quantityController;

  ProductFormData({
    this.productTemplateId,
    required this.quantity,
    required this.name,
    required this.calculatedVolume,
    required this.attributes,
    this.template,
    required this.attributeControllers,
    required this.quantityController,
  });
}

/// Форма создания/редактирования товара в пути
class ProductInTransitFormPage extends ConsumerStatefulWidget {
  final ProductInTransitModel? product;
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
  List<ProductFormData> _products = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    print('🔵 ProductInTransitFormPage: initState начат');
    print('🔵 ProductInTransitFormPage: widget.product = ${widget.product}');
    print('🔵 ProductInTransitFormPage: _isEditing = $_isEditing');
    
    _initializeForm();
    print('🔵 ProductInTransitFormPage: _initializeForm завершен');
    
    _initializeProducts();
    print('🔵 ProductInTransitFormPage: _initializeProducts завершен, _products.length = ${_products.length}');
    print('🔵 ProductInTransitFormPage: _products = $_products');
    
    _loadData();
    print('🔵 ProductInTransitFormPage: initState завершен');
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
      
      print('🔵 ProductInTransitFormPage: Инициализация формы для редактирования товара ID: ${product.id}');
      print('🔵 ProductInTransitFormPage: product_template_id: ${product.productTemplateId}');
    }
  }

  void _initializeProducts() {
    print('🔵 ProductInTransitFormPage: _initializeProducts начат');

    if (_isEditing && widget.product != null) {
      // Режим редактирования - заполняем данными из существующего товара
      final product = widget.product!;
      print('🔵 ProductInTransitFormPage: Режим редактирования, заполняем данными товара');

      // Создаем контроллеры для атрибутов
      final attributeControllers = <String, TextEditingController>{};
      final attributes = <String, dynamic>{};

      if (product.attributes is Map<String, dynamic>) {
        final productAttributes = product.attributes as Map<String, dynamic>;
        productAttributes.forEach((key, value) {
          attributeControllers[key] = TextEditingController(text: value?.toString() ?? '');
          attributes[key] = value;
        });
      }

      _products = [
        ProductFormData(
          productTemplateId: product.productTemplateId,
          quantity: product.quantity,
          name: product.name ?? '',
          calculatedVolume: product.calculatedVolume ?? '',
          attributes: attributes,
          template: null, // Загрузим позже в _loadData
          attributeControllers: attributeControllers,
          quantityController: TextEditingController(text: product.quantity),
        ),
      ];
      print('🔵 ProductInTransitFormPage: Товар для редактирования создан: ${_products[0]}');
    } else {
      // Режим создания - создаем пустой товар
      print('🔵 ProductInTransitFormPage: Режим создания, создаем пустой товар');
      _products = [
        ProductFormData(
          productTemplateId: null,
          quantity: '',
          name: '',
          calculatedVolume: '',
          attributes: {},
          template: null,
          attributeControllers: {},
          quantityController: TextEditingController(),
        ),
      ];
      print('🔵 ProductInTransitFormPage: Пустой товар создан: ${_products[0]}');
    }

    print('🔵 ProductInTransitFormPage: _initializeProducts завершен, _products.length = ${_products.length}');
  }

  void _addProduct() {
    setState(() {
      _products.add(
        ProductFormData(
          productTemplateId: null,
          quantity: '',
          name: '',
          calculatedVolume: '',
          attributes: {},
          template: null,
          attributeControllers: {},
          quantityController: TextEditingController(),
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
        _products[index].quantityController.dispose();
        _products.removeAt(index);
      });
    }
  }

  Future<void> _loadData() async {
    print('🔵 ProductInTransitFormPage: _loadData начат');
    print('🔵 ProductInTransitFormPage: _products перед загрузкой данных: $_products');
    setState(() => _isLoading = true);

    try {
      // Загружаем склады
      print('🔵 ProductInTransitFormPage: Загружаем склады...');
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      print('🔵 ProductInTransitFormPage: Склады загружены: ${_warehouses.length} шт');

      // Загружаем производителей
      print('🔵 ProductInTransitFormPage: Загружаем производителей...');
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
        print('🔵 ProductInTransitFormPage: Производители загружены: ${_producers.length} шт');
      } else {
        print('🔵 ProductInTransitFormPage: Производители не загружены');
      }

      // Загружаем шаблоны товаров
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final templatesResponse = await templateDataSource.getProductTemplates();
      _productTemplates = templatesResponse;
      print('🔵 ProductInTransitFormPage: Шаблоны товаров загружены: ${_productTemplates.length} шт');

      // Если редактируем, загружаем атрибуты для товаров
      if (_isEditing) {
        print('🔵 ProductInTransitFormPage: Загружаем атрибуты для редактирования товаров...');
        for (int i = 0; i < _products.length; i++) {
          if (_products[i].productTemplateId != null) {
            await _loadProductTemplateAttributes(i, _products[i].productTemplateId!);
          }
        }
      }

      print('🔵 ProductInTransitFormPage: _loadData завершен успешно');
      print('🔵 ProductInTransitFormPage: _products после загрузки данных: $_products');

    } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка загрузки данных: $e');
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
        print('🔵 ProductInTransitFormPage: _loadData завершен, _isLoading = false');
      }
    }
  }

  Future<void> _loadTemplateAttributes() async {
    // В новой системе множественных товаров шаблоны загружаются индивидуально для каждого товара
    // Этот метод оставляем для совместимости со старой системой
    print('🔵 ProductInTransitFormPage: _loadTemplateAttributes вызван (устаревший метод)');
    return;
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
      
      print('🔵 ProductInTransitFormPage: Формула для расчета: $formula');
      
      // Простой парсер математических выражений
      final result = _evaluateFormula(formula);
      
      return result.toStringAsFixed(3);
    } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка расчета объема: $e');
      return '0';
    }
  }

  double _evaluateFormula(String formula) {
    try {
      // Используем библиотеку math_expressions для правильного парсинга
      final parser = Parser();
      final expression = parser.parse(formula);
      final contextModel = ContextModel();

      final result = expression.evaluate(EvaluationType.REAL, contextModel);
      return result as double;
    } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка парсинга формулы: $e');
      print('🔴 ProductInTransitFormPage: Формула: $formula');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 ProductInTransitFormPage: build вызван, _isLoading = $_isLoading');
    print('🔵 ProductInTransitFormPage: _warehouses.length = ${_warehouses.length}');
    print('🔵 ProductInTransitFormPage: _producers.length = ${_producers.length}');
    print('🔵 ProductInTransitFormPage: _productTemplates.length = ${_productTemplates.length}');

    if (_isLoading) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Редактирование товара в пути' : 'Создание товара в пути'),
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

                  // 3. Дата отгрузки
            _buildDateField(
                    label: 'Дата отгрузки',
                    selectedDate: _selectedShippingDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedShippingDate = date;
                      });
                    },
                  ),
            const SizedBox(height: 16),

                  // 4. Дата поступления
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
            
                  // 5. Номер транспортного средства
            _buildTextField(
              controller: _transportNumberController,
              label: 'Номер транспортного средства',
            ),
            const SizedBox(height: 16),

                  // 6. Место отгрузки
            _buildTextField(
              controller: _shippingLocationController,
                    label: 'Место отгрузки',
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
                      onPressed: _isEditing ? _updateProduct : _submitForm,
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
      controller: product.quantityController,
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
              labelText: 'Производитель *',
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
      validator: (value) {
        if (value == null) {
          return 'Выберите производителя';
        }
        return null;
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
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
    );
  }


  Widget _buildTransportNumberField() {
    return TextFormField(
      controller: _transportNumberController,
      decoration: InputDecoration(
        labelText: 'Номер транспорта',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      readOnly: widget.isViewMode,
    );
  }

  Widget _buildArrivalDateField() {
    return InkWell(
      onTap: widget.isViewMode ? null : _selectArrivalDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Дата поступления',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedArrivalDate != null
              ? DateFormat('dd.MM.yyyy').format(_selectedArrivalDate!)
              : 'Выберите дату',
        ),
      ),
    );
  }

  Future<void> _selectArrivalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedArrivalDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (date != null) {
      setState(() {
        _selectedArrivalDate = date;
      });
    }
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
          onChanged: (value) => _onProductAttributeChanged(controller),
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
          onChanged: (value) => _onProductAttributeChanged(controller),
        );
    }

    return field;
  }


  Widget _buildNumberField(ProductAttributeModel attribute, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '${attribute.name}${attribute.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixText: attribute.unit,
      ),
      keyboardType: TextInputType.number,
      readOnly: widget.isViewMode,
      onChanged: (value) => _onAttributeChanged(),
      validator: attribute.isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Поле обязательно для заполнения';
        }
        if (double.tryParse(value) == null) {
          return 'Введите корректное число';
        }
        return null;
      } : null,
    );
  }

  Widget _buildSelectField(ProductAttributeModel attribute, TextEditingController controller) {
    List<String> options = [];
    
    if (attribute.options is String) {
      try {
        final decoded = json.decode(attribute.options as String) as List;
        options = decoded.cast<String>();
      } catch (e) {
        print('🔴 Ошибка парсинга опций: $e');
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


  Widget _buildCalculatedVolumeField() {
    return TextFormField(
      controller: _calculatedVolumeController,
      decoration: InputDecoration(
        labelText: 'Объем',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixText: _selectedTemplate?.unit,
        helperText: 'Рассчитывается автоматически',
      ),
      readOnly: true,
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
    print('🔵 ProductInTransitFormPage: _onProductTemplateChanged для товара $index, templateId = $templateId');
    print('🔵 ProductInTransitFormPage: _products до изменения: $_products');
    
    setState(() {
      _products[index] = ProductFormData(
        productTemplateId: templateId,
        quantity: _products[index].quantity,
        name: _products[index].name,
        calculatedVolume: _products[index].calculatedVolume,
        attributes: _products[index].attributes,
        template: templateId != null ? _productTemplates.firstWhere((t) => t.id == templateId) : null,
        attributeControllers: _products[index].attributeControllers,
        quantityController: _products[index].quantityController,
      );
    });
    
    print('🔵 ProductInTransitFormPage: _products после изменения: $_products');

    if (templateId != null) {
      print('🔵 ProductInTransitFormPage: Загружаем атрибуты для шаблона $templateId');
      _loadProductTemplateAttributes(index, templateId);
    } else {
      print('🔵 ProductInTransitFormPage: Шаблон не выбран, очищаем наименование и объем');
      // Если шаблон не выбран, очищаем наименование и объем
      _calculateProductNameAndVolume(index);
    }
  }

  void _onProductQuantityChanged(int index, String quantity) {
    print('🔵 ProductInTransitFormPage: _onProductQuantityChanged для товара $index, quantity = $quantity');
    print('🔵 ProductInTransitFormPage: _products до изменения: $_products');
    
    setState(() {
      _products[index] = ProductFormData(
        productTemplateId: _products[index].productTemplateId,
        quantity: quantity,
        name: _products[index].name,
        calculatedVolume: _products[index].calculatedVolume,
        attributes: _products[index].attributes,
        template: _products[index].template,
        attributeControllers: _products[index].attributeControllers,
        quantityController: _products[index].quantityController, // Сохраняем контроллер
      );
    });
    
    print('🔵 ProductInTransitFormPage: _products после изменения: $_products');
    
    // Пересчитываем наименование и объем
    _calculateProductNameAndVolume(index);
  }

  void _onProductAttributeChanged(TextEditingController controller) {
    print('🔵 ProductInTransitFormPage: _onProductAttributeChanged вызван');
    print('🔵 ProductInTransitFormPage: _products = $_products');
    
    // Находим индекс товара по контроллеру атрибута
    for (int i = 0; i < _products.length; i++) {
      print('🔵 ProductInTransitFormPage: Проверяем товар $i, attributeControllers = ${_products[i].attributeControllers.keys.toList()}');
      if (_products[i].attributeControllers.containsValue(controller)) {
        print('🔵 ProductInTransitFormPage: Найден товар $i, вызываем _calculateProductNameAndVolume');
        _calculateProductNameAndVolume(i);
        break;
      }
    }
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
        // Заполняем значение из существующих атрибутов товара при редактировании
        final existingValue = _isEditing && widget.product != null
          ? _products[index].attributes[attribute.variable]?.toString() ?? ''
          : '';

        newAttributeControllers[attribute.variable] = TextEditingController(text: existingValue);
      }
      
        setState(() {
        _products[index] = ProductFormData(
          productTemplateId: templateId,
          quantity: _products[index].quantity,
          name: _products[index].name,
          calculatedVolume: _products[index].calculatedVolume,
          attributes: _products[index].attributes,
          template: template,
          attributeControllers: newAttributeControllers,
          quantityController: _products[index].quantityController,
        );
      });
      
      _calculateProductNameAndVolume(index);
    } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка загрузки атрибутов шаблона: $e');
    }
  }

  void _calculateProductNameAndVolume(int index) {
    final product = _products[index];
    if (product.template == null || product.quantity.isEmpty) {
        setState(() {
        _products[index] = ProductFormData(
          productTemplateId: product.productTemplateId,
          quantity: product.quantity,
          name: '',
          calculatedVolume: '',
          attributes: product.attributes,
          template: product.template,
          attributeControllers: product.attributeControllers,
          quantityController: product.quantityController,
        );
        });
        return;
      }
      
    // Формируем наименование
    final name = _generateProductName(index);
    
    // Рассчитываем объем по формуле
    final volume = _calculateProductVolume(index);

      setState(() {
      _products[index] = ProductFormData(
        productTemplateId: product.productTemplateId,
        quantity: product.quantity,
        name: name,
        calculatedVolume: volume,
        attributes: product.attributes,
        template: product.template,
        attributeControllers: product.attributeControllers,
        quantityController: product.quantityController,
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
      
      print('🔵 ProductInTransitFormPage: Формула для расчета: $formula');
      
      // Простой парсер математических выражений
      final result = _evaluateFormula(formula);
      
      return result.toStringAsFixed(3);
    } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка расчета объема: $e');
      return '0';
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔵 ProductInTransitFormPage: Создание товара');
      
      final provider = ref.read(productsInTransitProvider.notifier);
      
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          attributes[entry.key] = entry.value.text;
        }
      }

      final request = CreateProductInTransitRequest(
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
      print('🔴 ProductInTransitFormPage: Ошибка создания товара: $e');
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
      print('🔵 ProductInTransitFormPage: Обновление товара ID: ${widget.product!.id}');
      
      final provider = ref.read(productsInTransitProvider.notifier);
      
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          attributes[entry.key] = entry.value.text;
        }
      }

      final request = UpdateProductInTransitRequest(
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
      print('🔴 ProductInTransitFormPage: Ошибка обновления товара: $e');
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

  Future<void> _submitForm() async {
    print('🔵 ProductInTransitFormPage: _submitForm начат');
    print('🔵 ProductInTransitFormPage: _formKey.currentState = ${_formKey.currentState}');
    
    if (!_formKey.currentState!.validate()) {
      print('🔵 ProductInTransitFormPage: Валидация формы не прошла');
      return;
    }
    
    print('🔵 ProductInTransitFormPage: Валидация формы прошла успешно');

    // Проверяем, что выбран склад
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите склад'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Проверяем, что есть товары для создания
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы один товар'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

        try {
          print('🔵 ProductInTransitFormPage: Создание товаров');
          print('🔵 ProductInTransitFormPage: _products.length = ${_products.length}');
          print('🔵 ProductInTransitFormPage: _selectedWarehouseId = $_selectedWarehouseId');
          print('🔵 ProductInTransitFormPage: _products = $_products');

          // Проверяем, что _products не пустой
          if (_products.isEmpty) {
            print('🔴 ProductInTransitFormPage: _products пустой!');
            throw Exception('Нет товаров для создания');
          }

          // Подготавливаем товары для API
          final products = <ProductInTransitItem>[];
          
          for (int i = 0; i < _products.length; i++) {
            final product = _products[i];
            print('🔵 ProductInTransitFormPage: Обрабатываем товар $i');
            print('🔵 ProductInTransitFormPage: product.productTemplateId = ${product.productTemplateId}');
            print('🔵 ProductInTransitFormPage: product.quantity = ${product.quantity}');
            print('🔵 ProductInTransitFormPage: product.name = ${product.name}');

            // Проверяем обязательные поля для каждого товара
            if (product.productTemplateId == null) {
              throw Exception('Выберите шаблон товара для товара ${i + 1}');
            }
            if (product.quantity.isEmpty) {
              throw Exception('Введите количество для товара ${i + 1}');
            }

            print('🔵 ProductInTransitFormPage: Собираем атрибуты для товара $i');
            // Собираем атрибуты для товара
            final attributes = <String, dynamic>{};
            for (final entry in product.attributeControllers.entries) {
              if (entry.value.text.isNotEmpty) {
                attributes[entry.key] = entry.value.text;
              }
            }
            print('🔵 ProductInTransitFormPage: Атрибуты собраны: $attributes');

            // Создаем элемент товара для API
            final productItem = ProductInTransitItem(
              productTemplateId: product.productTemplateId!,
              quantity: product.quantity,
              name: product.name,
              attributes: attributes,
            );
            
            products.add(productItem);
            print('🔵 ProductInTransitFormPage: Товар $i подготовлен для API');
          }

          print('🔵 ProductInTransitFormPage: Создаем запрос для всех товаров');
          // Создаем запрос для всех товаров
          final request = CreateMultipleProductsInTransitRequest(
            warehouseId: _selectedWarehouseId!,
            transportNumber: _transportNumberController.text.isNotEmpty ? _transportNumberController.text : null,
            shippingLocation: _shippingLocationController.text.isNotEmpty ? _shippingLocationController.text : null,
            shippingDate: _selectedShippingDate != null ? DateFormat('yyyy-MM-dd').format(_selectedShippingDate!) : null,
            arrivalDate: _selectedArrivalDate?.toIso8601String(),
            expectedArrivalDate: _selectedArrivalDate != null ? DateFormat('yyyy-MM-dd').format(_selectedArrivalDate!) : null,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            products: products,
          );

          print('🔵 ProductInTransitFormPage: Создаем товары по одному через старый API');
          final createdProducts = <ProductInTransitModel>[];
          
          for (int i = 0; i < _products.length; i++) {
            final product = _products[i];
            print('🔵 ProductInTransitFormPage: Создаем товар $i через старый API');
            
            // Создаем запрос для одного товара через старый API
            final singleRequest = CreateProductInTransitRequest(
              warehouseId: _selectedWarehouseId!,
              productTemplateId: product.productTemplateId!,
              quantity: product.quantity,
              name: product.name,
              calculatedVolume: product.calculatedVolume,
              attributes: product.attributes,
              transportNumber: _transportNumberController.text.isNotEmpty ? _transportNumberController.text : null,
              arrivalDate: _selectedArrivalDate?.toIso8601String(),
              shippingLocation: _shippingLocationController.text.isNotEmpty ? _shippingLocationController.text : null,
              shippingDate: _selectedShippingDate?.toIso8601String(),
              notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            );
            
            final createdProduct = await ref.read(productsInTransitProvider.notifier).createProduct(singleRequest);
            createdProducts.add(createdProduct);
            print('🔵 ProductInTransitFormPage: Товар $i создан успешно');
          }
          
          print('🔵 ProductInTransitFormPage: Все товары созданы успешно: ${createdProducts.length}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Создано товаров: ${createdProducts.length}'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
      print('🔴 ProductInTransitFormPage: Ошибка создания товара: $e');
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
        setState(() => _isLoading = false);
      }
    }
  }
}
