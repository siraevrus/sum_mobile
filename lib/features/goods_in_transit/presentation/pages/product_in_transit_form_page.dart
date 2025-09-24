import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/goods_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';
import 'package:sum_warehouse/features/goods_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/goods_in_transit/data/repositories/products_in_transit_repository.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart' as shared;
import 'package:sum_warehouse/core/models/api_response_model.dart' as core;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// Модель товара для добавления в список
class ProductItem {
  final int? productTemplateId;
  final String name;
  final String? description;
  final double quantity;
  final String? producer;

  ProductItem({
    required this.productTemplateId,
    required this.name,
    this.description,
    required this.quantity,
    this.producer,
  });
}

/// Экран создания/редактирования товара в пути
class ProductInTransitFormPage extends ConsumerStatefulWidget {
  final int? productId;
  final bool isEditing;

  const ProductInTransitFormPage({
    super.key,
    this.productId,
    required this.isEditing,
  });

  @override
  ConsumerState<ProductInTransitFormPage> createState() => _ProductInTransitFormPageState();
}

class _ProductInTransitFormPageState extends ConsumerState<ProductInTransitFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Контроллеры для полей формы
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _transportNumberController = TextEditingController();
  final _shippingLocationController = TextEditingController();
  final _notesController = TextEditingController();


  // Выбранные значения
  int? _selectedWarehouseId;
  int? _selectedProductTemplateId;
  int? _selectedProducerId;
  String? _selectedProductTemplateName;
  DateTime? _shippingDate;
  DateTime? _expectedArrivalDate;
  double? _calculatedValue;


  // Атрибуты товара
  final Map<String, dynamic> _attributes = {};
  final _attributeControllers = <String, TextEditingController>{};
  List<dynamic> _loadedTemplateAttributes = [];
  
  // Загруженные файлы
  List<String> _selectedFiles = [];

  // Список товаров для создания
  List<ProductItem> _productItems = [];

  @override
  void initState() {
    super.initState();
    // Загружаем производителей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(producersProvider.notifier).loadProducers();
    });
    
    if (widget.isEditing && widget.productId != null) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _transportNumberController.dispose();
    _shippingLocationController.dispose();
    _notesController.dispose();
    _attributeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  /// Инициализировать контроллеры для атрибутов шаблона
  void _initializeAttributeControllers(List<dynamic> attributes) {
    // attributes - list of attribute models (may vary by datasource)
    // Очистим старые контроллеры
    _attributeControllers.values.forEach((c) => c.dispose());
    _attributeControllers.clear();
    _attributes.clear();

    for (final attr in attributes) {
      // Поддерживаем разные форматы: модель с полем 'variable' и 'defaultValue'
      final variable = (attr is Map && attr['variable'] != null) ? attr['variable'].toString() : (attr.variable ?? '');
      final defaultValue = (attr is Map && attr['defaultValue'] != null) ? attr['defaultValue']?.toString() : (attr.defaultValue ?? null);
      final controller = TextEditingController();
      if (defaultValue != null) {
        controller.text = defaultValue.toString();
        _attributes[variable] = defaultValue;
      }
      if (variable.isNotEmpty) {
        _attributeControllers[variable] = controller;
      } else {
        controller.dispose();
      }
    }
    setState(() {});
  }

  /// Загрузить атрибуты выбранного шаблона и создать контроллеры
  Future<void> _loadTemplateAttributes(int templateId) async {
    try {
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final response = await dataSource.getTemplateAttributes(templateId);
      // Ожидаем список; если возвращен обёрнутый ответ, попробуем взять поле data
      final attrs = response is List ? response : (response as List?);
      if (attrs != null) {
        _loadedTemplateAttributes = attrs;
        _initializeAttributeControllers(attrs);
      }
    } catch (e) {
      print('Ошибка загрузки атрибутов шаблона: $e');
    }
  }

  Future<void> _loadProductData() async {
    if (widget.productId == null) return;

    setState(() => _isLoading = true);
    try {
      final datasource = ref.read(productsInTransitRemoteDataSourceProvider);
      final product = await datasource.getProductInTransitById(widget.productId!);
      
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _quantityController.text = product.quantity.toString();
      _transportNumberController.text = product.transportNumber ?? '';
      _shippingLocationController.text = product.shippingLocation ?? '';
      _notesController.text = product.notes ?? '';
      
      // Производитель будет загружен из выпадающего списка
      _selectedProducerId = null;
      
      _selectedWarehouseId = product.warehouseId;
      _selectedProductTemplateId = product.productTemplateId;
      _shippingDate = product.shippingDate;
      _expectedArrivalDate = product.expectedArrivalDate;
      
      // Загружаем характеристики из атрибутов если есть
      if (product.attributes != null) {
        final attributes = product.attributes!;
        // Можно добавить обработку атрибутов если нужно
      }
      
      // Загружаем файлы документов если есть
      if (product.documentPath != null) {
        _selectedFiles = List<String>.from(product.documentPath!);
      }
    } catch (e) {
      print('Ошибка загрузки товара в пути: $e'); // Для отладки
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isShippingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isShippingDate 
        ? (_shippingDate ?? DateTime.now())
        : (_expectedArrivalDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isShippingDate) {
          _shippingDate = picked;
        } else {
          _expectedArrivalDate = picked;
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.files.map((file) => file.path ?? file.name).toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файлов: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите склад назначения')),
      );
      return;
    }

    // Проверяем, что есть товары для создания
    if (_productItems.isEmpty && _selectedProductTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один товар')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      
      if (widget.isEditing && widget.productId != null) {
        // Для редактирования используем текущий товар
        final attributes = <String, dynamic>{};
        final data = {
          'product_template_id': _selectedProductTemplateId,
          'warehouse_id': _selectedWarehouseId,
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'quantity': double.parse(_quantityController.text),
          'transport_number': _transportNumberController.text.trim().isEmpty ? null : _transportNumberController.text.trim(),
          'producer_id': _selectedProducerId,
          'shipping_location': _shippingLocationController.text.trim().isEmpty ? null : _shippingLocationController.text.trim(),
          'shipping_date': _shippingDate?.toIso8601String(),
          'expected_arrival_date': _expectedArrivalDate?.toIso8601String(),
          'arrival_date': _expectedArrivalDate?.toIso8601String(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'attributes': attributes.isEmpty ? null : attributes,
          'status': 'in_transit',
          'document_path': _selectedFiles.isEmpty ? null : _selectedFiles,
        };
        
        await repository.updateProductInTransit(widget.productId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Товар успешно обновлен')),
          );
        }
      } else {
        // Для создания: создаем все товары из списка + текущий товар если есть
        final allProducts = List<ProductItem>.from(_productItems);
        
        // Добавляем текущий товар если он заполнен
        if (_selectedProductTemplateId != null && _nameController.text.trim().isNotEmpty) {
          // Получаем имя производителя из выбранного ID
          String? currentProducerName;
          if (_selectedProducerId != null) {
            final producersAsync = ref.read(producersProvider);
            producersAsync.whenData((producers) {
              final producer = producers.firstWhere(
                (p) => p.id == _selectedProducerId,
                orElse: () => producers.first,
              );
              currentProducerName = producer.name;
            });
          }
          
          allProducts.add(ProductItem(
            productTemplateId: _selectedProductTemplateId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            quantity: double.tryParse(_quantityController.text) ?? 0.0,
            producer: currentProducerName,
          ));
        }

        int successCount = 0;
        int totalCount = allProducts.length;

        // Создаем каждый товар отдельно
        for (final product in allProducts) {
          try {
            final attributes = <String, dynamic>{};
            final data = {
              'product_template_id': product.productTemplateId,
              'warehouse_id': _selectedWarehouseId,
              'name': product.name,
              'description': product.description,
              'quantity': product.quantity,
              'transport_number': _transportNumberController.text.trim().isEmpty ? null : _transportNumberController.text.trim(),
              'producer_id': _selectedProducerId,
              'shipping_location': _shippingLocationController.text.trim().isEmpty ? null : _shippingLocationController.text.trim(),
              'shipping_date': _shippingDate?.toIso8601String(),
              'expected_arrival_date': _expectedArrivalDate?.toIso8601String(),
              'arrival_date': _expectedArrivalDate?.toIso8601String(),
              'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              'attributes': attributes.isEmpty ? null : attributes,
              'status': 'in_transit',
              'document_path': _selectedFiles.isEmpty ? null : _selectedFiles,
            };
            
            await repository.createProductInTransit(data);
            successCount++;
          } catch (e) {
            print('Ошибка создания товара ${product.name}: $e');
          }
        }

        if (mounted) {
          if (successCount == totalCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Успешно создано товаров: $successCount')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Создано товаров: $successCount из $totalCount')),
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Редактирование товара' : 'Добавить товар в пути'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildProductSection(),
                    const SizedBox(height: 24),
                    _buildDocumentsSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
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
        _buildWarehouseDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _shippingLocationController,
          label: 'Место отгрузки',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Дата отгрузки',
          date: _shippingDate,
          onTap: () => _selectDate(context, true),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _transportNumberController,
          label: 'Номер транспорта',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Ожидаемая дата прибытия',
          date: _expectedArrivalDate,
          onTap: () => _selectDate(context, false),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: 'Заметки',
          isRequired: false,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Товары'),
        const SizedBox(height: 16),
        // Список товаров с возможностью добавления/удаления
        _buildProductsList(),
        const SizedBox(height: 16),
        _buildProductTemplateDropdown(),
        const SizedBox(height: 16),
        // Нередактируемое поле наименования (генерируется автоматически как в ProductFormPage)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
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
        const SizedBox(height: 16),
        // Динамические поля атрибутов шаблона
        if (_loadedTemplateAttributes.isNotEmpty) ...[
          _buildSectionTitle('Характеристики'),
          const SizedBox(height: 16),
          ..._loadedTemplateAttributes.map((attribute) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAttributeFieldTransit(attribute),
              )),
          const SizedBox(height: 8),
        ],
        _buildProducerDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _quantityController,
          label: 'Количество*',
          isRequired: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        // Поле 'Рассчитанный объем' удалено
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Описание',
          isRequired: false,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Список товаров',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        // Добавленные товары
        ..._buildProductItems(),
        const SizedBox(height: 8),
        // Кнопка добавления товара
        OutlinedButton.icon(
          onPressed: _addProduct,
          icon: const Icon(Icons.add),
          label: const Text('Добавить товар'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProductItems() {
    final items = <Widget>[];
    
    // Показываем добавленные товары
    for (int i = 0; i < _productItems.length; i++) {
      final product = _productItems[i];
      items.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Количество: ${product.quantity}${product.producer != null ? ', Производитель: ${product.producer}' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeProductItem(i),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Удалить товар',
              ),
            ],
          ),
        ),
      );
      items.add(const SizedBox(height: 8));
    }
    
    // Показываем текущий товар в процессе заполнения, если есть данные
    if (_nameController.text.isNotEmpty || _selectedProductTemplateId != null) {
      items.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.edit, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _nameController.text.isNotEmpty 
                    ? '${_nameController.text} (редактируется)' 
                    : 'Новый товар (редактируется)',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: _removeCurrentProduct,
                icon: const Icon(Icons.clear, color: Colors.orange),
                tooltip: 'Очистить форму',
              ),
            ],
          ),
        ),
      );
      items.add(const SizedBox(height: 8));
    }
    
    return items;
  }

  void _addProduct() {
    // Проверяем, что обязательные поля заполнены
    final generatedName = _getGeneratedProductName();
    final effectiveName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (generatedName.startsWith('Автоматически') ? '' : generatedName);

    if (effectiveName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите наименование товара')),
      );
      return;
    }

    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите количество товара')),
      );
      return;
    }
    if (_selectedProductTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите шаблон товара')),
      );
      return;
    }

    // Создаем товар и добавляем в список
    // Получаем имя производителя из выбранного ID
    String? producerName;
    if (_selectedProducerId != null) {
      final producersAsync = ref.read(producersProvider);
      producersAsync.whenData((producers) {
        final producer = producers.firstWhere(
          (p) => p.id == _selectedProducerId,
          orElse: () => producers.first,
        );
        producerName = producer.name;
      });
    }
    
    final product = ProductItem(
      productTemplateId: _selectedProductTemplateId,
      name: effectiveName,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 0.0,
      producer: producerName,
    );

    setState(() {
      _productItems.add(product);
      // Очищаем поля для следующего товара
      _nameController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _selectedProductTemplateId = null;
      _selectedProducerId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Товар добавлен в список'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeCurrentProduct() {
    setState(() {
      _nameController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _selectedProductTemplateId = null;
      _selectedProducerId = null;
    });
  }

  void _removeProductItem(int index) {
    setState(() {
      _productItems.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Товар удален из списка'),
        duration: Duration(seconds: 2),
      ),
    );
  }



  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Документы'),
        const SizedBox(height: 16),
        // Область загрузки файлов
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Нажмите для выбора файлов',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'PDF, DOC, DOCX, JPG, PNG',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Список выбранных файлов
        if (_selectedFiles.isNotEmpty) ...[
          const Text(
            'Выбранные файлы:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...List.generate(_selectedFiles.length, (index) {
            final fileName = _selectedFiles[index].split('/').last;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFile(index),
                    icon: const Icon(Icons.close, color: Colors.red),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 16),
        ...children,
      ],
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
    required bool isRequired,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label*' : label,
        helperText: helperText,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: Colors.grey.shade500),
        helperStyle: TextStyle(color: Colors.grey.shade600),
      ),
      style: const TextStyle(color: Colors.black87),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: isRequired
          ? (value) => value?.isEmpty == true ? 'Поле обязательно для заполнения' : null
          : null,
    );
  }

  Widget _buildAttributeFieldTransit(dynamic attr) {
    // Accept either TemplateAttributeModel or Map-like structure
    TemplateAttributeModel attribute;
    if (attr is TemplateAttributeModel) {
      attribute = attr;
    } else if (attr is Map<String, dynamic>) {
      attribute = TemplateAttributeModel.fromJson(attr);
    } else {
      // Fallback: try to convert via toEntity if possible
      attribute = attr as TemplateAttributeModel;
    }

    final variable = attribute.variable;

    // use string-based type to avoid importing enums
    switch (attribute.type) {
      case 'number':
        _attributeControllers.putIfAbsent(variable, () => TextEditingController(text: attribute.defaultValue ?? ''));
        return TextFormField(
          controller: _attributeControllers[variable],
          decoration: InputDecoration(
            labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
            hintText: attribute.defaultValue,
            border: const OutlineInputBorder(),
            suffixText: attribute.unit,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _attributes[variable] = value;
            if (attribute.isInFormula) _calculateFormula();
          },
          validator: attribute.isRequired
              ? (value) => value == null || value.trim().isEmpty ? '${attribute.name} обязательно' : null
              : null,
        );

      case 'text':
        _attributeControllers.putIfAbsent(variable, () => TextEditingController(text: attribute.defaultValue ?? ''));
        return TextFormField(
          controller: _attributeControllers[variable],
          decoration: InputDecoration(
            labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
            hintText: attribute.defaultValue,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => _attributes[variable] = value,
          validator: attribute.isRequired
              ? (value) => value == null || value.trim().isEmpty ? '${attribute.name} обязательно' : null
              : null,
        );

      case 'select':
        // build options
        List<String> options = attribute.selectOptions ?? [];
        if (options.isEmpty) {
          if (attribute.options != null) {
            if (attribute.options is List) options = (attribute.options as List).map((e) => e.toString()).toList();
            else if (attribute.options is String) options = (attribute.options as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          } else if (attribute.value != null) {
            if (attribute.value is List) options = (attribute.value as List).map((e) => e.toString()).toList();
            else if (attribute.value is String) options = (attribute.value as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }

        final current = _attributes[variable]?.toString();
        return DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          value: options.contains(current) ? current : null,
          decoration: InputDecoration(
            labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
            border: const OutlineInputBorder(),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => setState(() => _attributes[variable] = v),
          validator: attribute.isRequired ? (v) => v == null || v.isEmpty ? 'Выберите ${attribute.name.toLowerCase()}' : null : null,
        );

      case 'boolean':
        final currentBool = _attributes[variable] as bool? ?? false;
        return CheckboxListTile(
          title: Text(attribute.name),
          value: currentBool,
          onChanged: (v) => setState(() => _attributes[variable] = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        );

      case 'date':
        final value = _attributes[variable] as DateTime?;
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _attributes[variable] = date);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: attribute.isRequired ? '${attribute.name} *' : attribute.name,
              border: const OutlineInputBorder(),
            ),
            child: Text(value != null ? '${value.day.toString().padLeft(2,'0')}.${value.month.toString().padLeft(2,'0')}.${value.year}' : 'Выберите дату'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _calculateFormula() {
    // Best-effort simple formula calculation for length*width*height example
    try {
      // Look for common keys
      final length = double.tryParse(_attributes['length']?.toString() ?? '') ?? 0;
      final width = double.tryParse(_attributes['width']?.toString() ?? '') ?? 0;
      final height = double.tryParse(_attributes['height']?.toString() ?? '') ?? 0;
      if (length > 0 && width > 0 && height > 0) {
        final result = length * width * height / 1000000;
        setState(() {
          _calculatedValue = result;
        });
      }
    } catch (_) {}
  }

  Widget _buildWarehouseDropdown() {
    return FutureBuilder<shared.PaginatedResponse<WarehouseModel>>(
      future: ref.read(warehousesRemoteDataSourceProvider).getWarehouses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final warehouses = snapshot.data?.data ?? [];
        
        return DropdownButtonFormField<int>(
          value: _selectedWarehouseId,
          decoration: InputDecoration(
            labelText: 'Склад назначения*',
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey.shade500),
          ),
          style: const TextStyle(color: Colors.black87),
          dropdownColor: Colors.white,
          items: warehouses.map((warehouse) {
            return DropdownMenuItem(
              value: warehouse.id,
              child: Text(warehouse.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWarehouseId = value;
            });
          },
          validator: (value) => value == null ? 'Выберите склад' : null,
        );
      },
    );
  }

  Widget _buildProductTemplateDropdown() {
    return FutureBuilder<core.PaginatedResponse<ProductTemplateModel>>(
      future: ref.read(productTemplateRemoteDataSourceProvider).getProductTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snapshot.data?.data ?? [];
        
        return DropdownButtonFormField<int>(
        value: _selectedProductTemplateId,
          decoration: InputDecoration(
            labelText: 'Шаблон товара*',
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey.shade500),
          ),
          style: const TextStyle(color: Colors.black87),
          dropdownColor: Colors.white,
          items: templates.map((template) {
            return DropdownMenuItem(
              value: template.id,
              child: Text(template.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProductTemplateId = value;
              _selectedProductTemplateName = value == null
                  ? null
                  : templates.firstWhere((t) => t.id == value).name;
            });
            if (value != null) {
              _loadTemplateAttributes(value);
            } else {
              // clear attributes/controllers when template cleared
              setState(() {
                _attributeControllers.clear();
                _attributes.clear();
              });
            }
          },
          validator: (value) => value == null ? 'Выберите шаблон товара' : null,
        );
      },
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequired ? '$label*' : label,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null 
                        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: date != null ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isEditing ? 'Сохранить изменения' : 'Добавить товар',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Генерировать название товара на основе шаблона и заполненных атрибутов
  String _getGeneratedProductName() {
    if (_selectedProductTemplateName == null) {
      return 'Автоматически формируется из характеристик товара (нередактируемое)';
    }

    final baseName = _selectedProductTemplateName!;
    final attributeParts = <String>[];

    // Собираем значения из контроллеров атрибутов
    for (final entry in _attributeControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) attributeParts.add(val);
    }

    // Дополнительные атрибуты
    for (final entry in _attributes.entries) {
      final val = entry.value?.toString() ?? '';
      if (val.isNotEmpty) attributeParts.add(val);
    }

    if (attributeParts.isNotEmpty) {
      return '$baseName (${attributeParts.join(', ')})';
    }

    return baseName;
  }
}
