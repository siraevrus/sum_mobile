import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/providers/products_inflow_provider.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';

/// Форма создания/редактирования товара
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _calculatedVolumeController = TextEditingController();
  final _transportNumberController = TextEditingController();
  final _shippingLocationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  int? _selectedWarehouseId;
  int? _selectedProducerId;
  DateTime? _selectedArrivalDate;
  DateTime? _selectedShippingDate;
  DateTime? _selectedExpectedArrivalDate;

  // Данные из API
  List<WarehouseModel> _warehouses = [];
  List<ProducerModel> _producers = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _calculatedVolumeController.dispose();
    _transportNumberController.dispose();
    _shippingLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditing) {
      final product = widget.product!;
      _nameController.text = product.name ?? '';
      _descriptionController.text = product.description ?? '';
      _quantityController.text = product.quantity;
      _calculatedVolumeController.text = product.calculatedVolume ?? '';
      _transportNumberController.text = product.transportNumber ?? '';
      _shippingLocationController.text = product.shippingLocation ?? '';
      _notesController.text = product.notes ?? '';
      _isActive = product.isActive;
      _selectedWarehouseId = product.warehouseId;
      _selectedProducerId = product.producerId;

      if (product.arrivalDate != null) {
        _selectedArrivalDate = DateTime.parse(product.arrivalDate!);
      }
      if (product.shippingDate != null) {
        _selectedShippingDate = DateTime.parse(product.shippingDate!);
      }
      if (product.expectedArrivalDate != null) {
        _selectedExpectedArrivalDate = DateTime.parse(product.expectedArrivalDate!);
      }
    } else {
      // Автогенерация даты поступления для нового товара
      _selectedArrivalDate = DateTime.now();
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
        _producers = (producersState.value ?? []).cast<ProducerModel>();
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
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
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Основная информация
                    _buildSection(
                      title: 'Основная информация',
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Название товара *',
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Описание',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _quantityController,
                                label: 'Количество *',
                                isRequired: true,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _calculatedVolumeController,
                                label: 'Объем',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildWarehouseDropdown(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildProducerDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _transportNumberController,
                          label: 'Номер транспорта',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Даты
                    _buildSection(
                      title: 'Даты',
                      children: [
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
                        _buildDateField(
                          label: 'Ожидаемая дата прибытия',
                          selectedDate: _selectedExpectedArrivalDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedExpectedArrivalDate = date;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Дополнительная информация
                    _buildSection(
                      title: 'Дополнительная информация',
                      children: [
                        _buildTextField(
                          controller: _shippingLocationController,
                          label: 'Место отгрузки',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesController,
                          label: 'Заметки',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Активен'),
                          subtitle: const Text('Товар активен и доступен для использования'),
                          value: _isActive,
                          onChanged: widget.isViewMode ? null : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Кнопки действий
                    if (!widget.isViewMode)
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

                    if (widget.isViewMode)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ProductInflowFormPage(
                                  product: widget.product,
                                  isViewMode: false,
                                ),
                              ),
                            );
                          },
                          child: const Text('Редактировать'),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: widget.isViewMode ? Colors.grey.shade100 : null,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Поле обязательно для заполнения';
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
        filled: true,
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
        filled: true,
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
  }) {
    return InkWell(
      onTap: widget.isViewMode ? null : () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        onDateSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: widget.isViewMode ? Colors.grey.shade100 : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: widget.isViewMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null ? Colors.black : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите склад')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateProductInflowRequest(
        productTemplateId: 1, // TODO: Добавить выбор шаблона товара
        warehouseId: _selectedWarehouseId!,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        quantity: _quantityController.text,
        calculatedVolume: _calculatedVolumeController.text.isEmpty ? null : _calculatedVolumeController.text,
        transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
        producerId: _selectedProducerId,
        arrivalDate: _selectedArrivalDate?.toIso8601String().split('T')[0],
        isActive: _isActive,
        status: 'in_stock',
        shippingLocation: _shippingLocationController.text.isEmpty ? null : _shippingLocationController.text,
        shippingDate: _selectedShippingDate?.toIso8601String().split('T')[0],
        expectedArrivalDate: _selectedExpectedArrivalDate?.toIso8601String().split('T')[0],
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref.read(productsInflowProvider.notifier).createProduct(request);

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
      final request = UpdateProductInflowRequest(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        quantity: _quantityController.text,
        calculatedVolume: _calculatedVolumeController.text.isEmpty ? null : _calculatedVolumeController.text,
        transportNumber: _transportNumberController.text.isEmpty ? null : _transportNumberController.text,
        producerId: _selectedProducerId,
        arrivalDate: _selectedArrivalDate?.toIso8601String().split('T')[0],
        isActive: _isActive,
        shippingLocation: _shippingLocationController.text.isEmpty ? null : _shippingLocationController.text,
        shippingDate: _selectedShippingDate?.toIso8601String().split('T')[0],
        expectedArrivalDate: _selectedExpectedArrivalDate?.toIso8601String().split('T')[0],
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref.read(productsInflowProvider.notifier).updateProduct(widget.product!.id, request);

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
