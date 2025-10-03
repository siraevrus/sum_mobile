import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/products_inflow_remote_datasource.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/providers/products_inflow_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Форма создания/редактирования товара в поступлении
class ProductInflowFormPage extends ConsumerStatefulWidget {
  final ProductInflowModel? product;
  final bool isViewMode;

  const ProductInflowFormPage({
    super.key,
    this.product,
    this.isViewMode = false,
  });

  @override
  ConsumerState<ProductInflowFormPage> createState() => _ProductInflowFormPageState();
}

class _ProductInflowFormPageState extends ConsumerState<ProductInflowFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _transportNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _calculatedVolumeController = TextEditingController();

  bool _isLoading = false;
  int? _selectedWarehouseId;
  int? _selectedProducerId;
  int? _selectedProductTemplateId;
  DateTime? _selectedArrivalDate;

  List<WarehouseModel> _warehouses = [];
  List<ProducerModel> _producers = [];
  List<ProductTemplateModel> _productTemplates = [];
  ProductTemplateModel? _selectedTemplate;
  Map<String, TextEditingController> _attributeControllers = {};

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    print('🔵 ProductInflowFormPage: initState начат');
    _initializeForm();
    _loadData();
    print('🔵 ProductInflowFormPage: initState завершен');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _transportNumberController.dispose();
    _nameController.dispose();
    _calculatedVolumeController.dispose();
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
    }
  }

  Future<void> _loadData() async {
    print('🔵 ProductInflowFormPage: _loadData начат');
    setState(() => _isLoading = true);

    try {
      // Загружаем склады
      print('🔵 ProductInflowFormPage: Загружаем склады...');
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      print('🔵 ProductInflowFormPage: Склады загружены: ${_warehouses.length} шт');

      // Загружаем производителей
      print('🔵 ProductInflowFormPage: Загружаем производителей...');
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
        print('🔵 ProductInflowFormPage: Производители загружены: ${_producers.length} шт');
      } else {
        print('🔵 ProductInflowFormPage: Производители не загружены');
      }

      // Загружаем шаблоны товаров
      print('🔵 ProductInflowFormPage: Загружаем шаблоны товаров...');
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _productTemplates = await templateDataSource.getProductTemplates();
      print('🔵 ProductInflowFormPage: Шаблоны товаров загружены: ${_productTemplates.length} шт');

      setState(() {});
      print('🔵 ProductInflowFormPage: setState вызван, _isLoading = false');
    } catch (e) {
      print('🔴 ProductInflowFormPage: Ошибка загрузки данных: $e');
      print('🔴 ProductInflowFormPage: Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      print('🔵 ProductInflowFormPage: _loadData завершен, _isLoading = false');
    }
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

  Future<void> _loadTemplateAttributes() async {
    if (_selectedProductTemplateId == null) {
      _selectedTemplate = null;
      _clearAttributeControllers();
      return;
    }

    try {
      print('🔵 ProductInflowFormPage: Загружаем атрибуты шаблона ID: $_selectedProductTemplateId');
      final templateDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _selectedTemplate = await templateDataSource.getProductTemplate(_selectedProductTemplateId!);
      
      // Создаем контроллеры для атрибутов
      _clearAttributeControllers();
      for (final attribute in _selectedTemplate!.attributes) {
        _attributeControllers[attribute.variable] = TextEditingController();
        
        // Если редактируем существующий товар, заполняем значения из attributes
        if (_isEditing && widget.product!.attributes != null) {
          final attributes = widget.product!.attributes as Map<String, dynamic>?;
          if (attributes != null && attributes.containsKey(attribute.variable)) {
            _attributeControllers[attribute.variable]!.text = attributes[attribute.variable].toString();
          }
        }
        
        // Добавляем слушатель изменений
        _attributeControllers[attribute.variable]!.addListener(_onAttributeChanged);
      }
      
      print('🔵 ProductInflowFormPage: Загружено атрибутов: ${_selectedTemplate!.attributes.length}');
      setState(() {});
    } catch (e) {
      print('🔴 ProductInflowFormPage: Ошибка загрузки атрибутов шаблона: $e');
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
    _nameController.text = _generateProductName();

    // Рассчитываем объем по формуле
    _calculatedVolumeController.text = _calculateVolume();
  }

  String _generateProductName() {
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
      
      print('🔵 ProductInflowFormPage: Формула для расчета: $formula');
      
      // Простой парсер математических выражений
      // В реальном проекте лучше использовать библиотеку для парсинга математических выражений
      final result = _evaluateFormula(formula);
      
      return result.toStringAsFixed(4);
    } catch (e) {
      print('🔴 ProductInflowFormPage: Ошибка расчета объема: $e');
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
      print('🔴 ProductInflowFormPage: Ошибка парсинга формулы: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 ProductInflowFormPage: build вызван, _isLoading = $_isLoading');
    print('🔵 ProductInflowFormPage: _warehouses.length = ${_warehouses.length}');
    print('🔵 ProductInflowFormPage: _producers.length = ${_producers.length}');
    print('🔵 ProductInflowFormPage: _productTemplates.length = ${_productTemplates.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование товара' : 'Создание товара'),
        actions: widget.isViewMode ? null : [
          if (_isEditing)
            IconButton(
              onPressed: _deleteProduct,
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
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
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Блок "Товар"
                    _buildSection(
                      title: 'Товар',
                      children: [
                        // Выпадающее поле "Шаблон товара"
                        _buildProductTemplateDropdown(),
                        const SizedBox(height: 16),
                        
                        // Поле Количество
                        _buildTextField(
                          controller: _quantityController,
                          label: 'Количество *',
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _onQuantityChanged(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Динамические поля атрибутов
                        ..._buildAttributeFields(),
                        
                        // Поле Наименование (автоматически формируется)
                        _buildTextField(
                          controller: _nameController,
                          label: 'Наименование',
                          readOnly: true,
                          hintText: 'Формируется автоматически',
                        ),
                        const SizedBox(height: 16),
                        
                        // Рассчитанный объем (автоматически считается)
                        _buildTextField(
                          controller: _calculatedVolumeController,
                          label: 'Рассчитанный объем',
                          readOnly: true,
                          hintText: 'Рассчитывается по формуле',
                        ),
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
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите $label';
              }
              return null;
            }
          : null,
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

  Widget _buildProductTemplateDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedProductTemplateId,
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
        setState(() {
          _selectedProductTemplateId = value;
        });
        _onTemplateChanged();
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите шаблон товара';
        }
        return null;
      },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attribute.isInFormula)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.functions, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  'Используется в формуле',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (attribute.isInFormula) const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildSelectField(ProductAttributeModel attribute, TextEditingController controller) {
    // Парсим опции из JSON строки
    List<String> options = [];
    if (attribute.options != null) {
      try {
        if (attribute.options is String && (attribute.options as String).isNotEmpty) {
          // Простой парсинг для списка опций
          // В реальном проекте используйте jsonDecode
          final cleanOptions = (attribute.options as String).replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
          options = cleanOptions.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } else if (attribute.options is List) {
          // Если options уже список
          options = (attribute.options as List).map((e) => e.toString()).toList();
        }
      } catch (e) {
        print('🔴 ProductInflowFormPage: Ошибка парсинга опций: $e');
      }
    }

    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      decoration: InputDecoration(
        labelText: attribute.name + (attribute.isRequired ? ' *' : ''),
        border: const OutlineInputBorder(),
        filled: widget.isViewMode,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('Выберите ${attribute.name.toLowerCase()}')),
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
          return 'Выберите ${attribute.name.toLowerCase()}';
        }
        return null;
      } : null,
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

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Собираем атрибуты
      final Map<String, dynamic> attributes = {};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          final attribute = _selectedTemplate!.attributes.firstWhere(
            (a) => a.variable == entry.key,
            orElse: () => ProductAttributeModel(
              id: 0,
              productTemplateId: 0,
              name: '',
              variable: entry.key,
              type: 'text',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          // Преобразуем значение в правильный тип
          if (attribute.type == 'number') {
            attributes[entry.key] = double.tryParse(entry.value.text) ?? entry.value.text;
          } else {
            attributes[entry.key] = entry.value.text;
          }
        }
      }

      final createRequest = CreateProductInflowRequest(
        productTemplateId: _selectedProductTemplateId!,
        warehouseId: _selectedWarehouseId!,
        name: _nameController.text.isEmpty ? null : _nameController.text,
        quantity: _quantityController.text,
        calculatedVolume: _calculatedVolumeController.text.isEmpty ? null : _calculatedVolumeController.text,
        transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
        producerId: _selectedProducerId,
        arrivalDate: _selectedArrivalDate != null ? DateFormat('yyyy-MM-dd').format(_selectedArrivalDate!) : null,
        isActive: true,
        status: 'in_stock',
        attributes: attributes,
      );

      await ref.read(productsInflowProvider.notifier).createProduct(createRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар успешно создан')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания товара: $e')),
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
      // Собираем атрибуты
      final Map<String, dynamic> attributes = {};
      for (final entry in _attributeControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          final attribute = _selectedTemplate!.attributes.firstWhere(
            (a) => a.variable == entry.key,
            orElse: () => ProductAttributeModel(
              id: 0,
              productTemplateId: 0,
              name: '',
              variable: entry.key,
              type: 'text',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          // Преобразуем значение в правильный тип
          if (attribute.type == 'number') {
            attributes[entry.key] = double.tryParse(entry.value.text) ?? entry.value.text;
          } else {
            attributes[entry.key] = entry.value.text;
          }
        }
      }

      final updateRequest = UpdateProductInflowRequest(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        quantity: _quantityController.text,
        calculatedVolume: _calculatedVolumeController.text.isEmpty ? null : _calculatedVolumeController.text,
        transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
        producerId: _selectedProducerId,
        arrivalDate: _selectedArrivalDate != null ? DateFormat('yyyy-MM-dd').format(_selectedArrivalDate!) : null,
        attributes: attributes,
      );

      await ref.read(productsInflowProvider.notifier).updateProduct(widget.product!.id, updateRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар успешно обновлен')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления товара: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление товара'),
        content: const Text('Вы уверены, что хотите удалить этот товар?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(productsInflowProvider.notifier).deleteProduct(widget.product!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар успешно удален')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления товара: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
