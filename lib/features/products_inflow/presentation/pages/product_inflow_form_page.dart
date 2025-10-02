import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/products_inflow_remote_datasource.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/providers/products_inflow_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
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
  List<ProductTemplateReference> _productTemplates = [];

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
        _producers = (producersState.value ?? []).cast<ProducerModel>();
        print('🔵 ProductInflowFormPage: Производители загружены: ${_producers.length} шт');
      } else {
        print('🔵 ProductInflowFormPage: Производители не загружены');
      }

      // Загружаем шаблоны товаров
      print('🔵 ProductInflowFormPage: Загружаем шаблоны товаров...');
      final productsInflowDataSource = ref.read(productsInflowRemoteDataSourceProvider);
      final templatesResponse = await productsInflowDataSource.getProducts(ProductInflowFilters(perPage: 100));
      _productTemplates = templatesResponse.data.map((e) => ProductTemplateReference(
        id: e.productTemplateId, 
        name: e.template?.name, 
        unit: e.template?.unit
      )).toList();
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
    _calculateNameAndVolume();
  }

  void _calculateNameAndVolume() {
    if (_selectedProductTemplateId == null || _quantityController.text.isEmpty) {
      _nameController.text = '';
      _calculatedVolumeController.text = '';
      return;
    }

    final template = _productTemplates.firstWhere(
      (t) => t.id == _selectedProductTemplateId,
      orElse: () => ProductTemplateReference(id: 0, name: ''),
    );

    if (template.name != null) {
      // Формируем наименование: "Название шаблона x характеристики"
      _nameController.text = template.name!;
    }

    // Рассчитываем объем по формуле (если есть)
    // TODO: Реализовать расчет по формуле из template
    _calculatedVolumeController.text = '0';
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
          child: Text(template.name ?? 'ID ${template.id}'),
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
      final updateRequest = UpdateProductInflowRequest(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        quantity: _quantityController.text,
        calculatedVolume: _calculatedVolumeController.text.isEmpty ? null : _calculatedVolumeController.text,
        transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
        producerId: _selectedProducerId,
        arrivalDate: _selectedArrivalDate != null ? DateFormat('yyyy-MM-dd').format(_selectedArrivalDate!) : null,
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
