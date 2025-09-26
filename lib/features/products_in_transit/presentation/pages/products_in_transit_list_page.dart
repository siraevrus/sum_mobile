import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/constants/app_constants.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/products_in_transit_details_page.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/products/presentation/providers/products_provider.dart';
import 'package:sum_warehouse/features/auth/data/datasources/auth_local_datasource.dart';

/// Экран списка товаров в пути
class ProductsInTransitListPage extends ConsumerStatefulWidget {
  const ProductsInTransitListPage({super.key});

  @override
  ConsumerState<ProductsInTransitListPage> createState() => _ProductsInTransitListPageState();
}

class _ProductsInTransitListPageState extends ConsumerState<ProductsInTransitListPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  final _formKey = GlobalKey<FormState>();
  int? _selectedWarehouseId;
  int? _selectedProductTemplateId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _producerController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shippingLocationController = TextEditingController();
  DateTime? _selectedShippingDate;
  
  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _producerController.dispose();
    _nameController.dispose();
    _shippingLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Товары в пути'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateProductInTransitDialog,
            tooltip: 'Создать товар в пути',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(productsInTransitProvider.notifier).refresh(),
        tooltip: 'Обновить список',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск и фильтры
          _buildFilters(),
          
          // Список товаров в пути
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(productsInTransitProvider.notifier).refresh();
              },
              child: _buildProductsInTransitList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Column(
        children: [
          TextField(
        controller: _searchController,
        decoration: InputDecoration(
              hintText: 'Поиск товаров в пути...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        onChanged: (value) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (value == _searchController.text) {
                  ref.read(productsInTransitProvider.notifier).searchProductsInTransit(value);
            }
          });
        },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            value: _statusFilter,
            onChanged: (value) {
              setState(() {
                _statusFilter = value;
              });
              ref.read(productsInTransitProvider.notifier).filterByStatus(value);
            },
            decoration: InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Все')),
              DropdownMenuItem(value: 'in_transit', child: Text('В пути')),
              DropdownMenuItem(value: 'arrived', child: Text('Прибыл')),
              DropdownMenuItem(value: 'received', child: Text('Принят')),
              DropdownMenuItem(value: 'cancelled', child: Text('Отменен')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsInTransitList() {
    final productsInTransitAsync = ref.watch(productsInTransitProvider);

    return productsInTransitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки товаров в пути',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Детали ошибки:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'API URL: ${AppConstants.baseUrl}/products-in-transit',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: ref.read(authLocalDataSourceProvider.future).then((ds) => ds.getToken()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text(
                              'Проверка токена...',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            );
                          }
                          
                          final token = snapshot.data;
                          return Text(
                            token != null 
                              ? 'Токен: ${token.substring(0, 20)}...' 
                              : 'Токен отсутствует - требуется авторизация',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: token != null ? Colors.green.shade600 : Colors.orange.shade600, 
                              fontSize: 12
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                onPressed: () => ref.read(productsInTransitProvider.notifier).refresh(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      data: (productsInTransit) {
        print('🎯 Отображение списка товаров в пути: ${productsInTransit.length}');
        
        if (productsInTransit.isEmpty) {
          print('📭 Список пуст, показываю заглушку');
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              alignment: Alignment.center,
              child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                    'Нет товаров в пути',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ],
              ),
            ),
          );
        }

        print('📋 Отображаю список из ${productsInTransit.length} товаров');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productsInTransit.length,
          itemBuilder: (context, index) {
            print('🏗️ Строю карточку для товара ${index}: ${productsInTransit[index].name}');
            return _buildProductInTransitCard(productsInTransit[index]);
          },
        );
      },
    );
  }

  Widget _buildProductInTransitCard(ProductInTransitEntity productInTransit) {
    final status = _getProductInTransitStatus(productInTransit.status);
    final statusColor = _getStatusColor(productInTransit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openProductInTransitDetails(productInTransit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Наименование
                        Text(
                          productInTransit.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Производитель
                        if (productInTransit.producer != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.business, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Производитель: ${productInTransit.producer!}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        
                        // Склад назначения
                        if (productInTransit.warehouse != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.warehouse, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Склад: ${productInTransit.warehouse!.name}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        
                        // Место отправления
                        if (productInTransit.shippingLocation != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Отправлено из: ${productInTransit.shippingLocation!}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleProductInTransitAction(action, productInTransit),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('Просмотр'),
                          ],
                        ),
                      ),
                      if (productInTransit.status != ProductInTransitStatus.received.name &&
                          productInTransit.status != ProductInTransitStatus.cancelled.name)
                        const PopupMenuItem(
                          value: 'receive',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Принять'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (productInTransit.shippingDate != null) ...[
                Text(
                  'Дата отгрузки: ${_formatDate(productInTransit.shippingDate!)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
              ],
              if (productInTransit.expectedArrivalDate != null) ...[
              Text(
                  'Ожидаемая дата прибытия: ${_formatDate(productInTransit.expectedArrivalDate!)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
                const SizedBox(height: 4),
              ],
              if (productInTransit.warehouse != null) ...[
                Text(
                  'Склад: ${productInTransit.warehouse!.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
              ],

              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(productInTransit.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProductInTransitAction(String action, ProductInTransitEntity productInTransit) async {
    switch (action) {
      case 'view':
        _openProductInTransitDetails(productInTransit);
        break;
      case 'receive':
        await _receiveProductInTransit(productInTransit);
        break;
    }
  }

  void _openProductInTransitDetails(ProductInTransitEntity productInTransit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductsInTransitDetailsPage(productInTransitId: productInTransit.id),
      ),
    ).then((_) => ref.read(productsInTransitProvider.notifier).refresh());
  }

  Future<void> _receiveProductInTransit(ProductInTransitEntity productInTransit) async {
    final actualQuantityController = TextEditingController(text: productInTransit.quantity.toStringAsFixed(0));
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Принять товар'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Товар: ${productInTransit.name}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: actualQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Фактическое количество',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фактическое количество';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Заметки (необязательно)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Принять', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (actualQuantityController.text.isEmpty || double.tryParse(actualQuantityController.text) == null) {
          throw Exception('Необходимо ввести фактическое количество.');
        }
        final actualQuantity = double.parse(actualQuantityController.text);
        final notes = notesController.text.isNotEmpty ? notesController.text : null;

        final request = ReceiveProductInTransitRequest(
          actualQuantity: actualQuantity,
          notes: notes,
        );

        await ref.read(productsInTransitProvider.notifier).receiveProductInTransit(
          productInTransit.id,
          request,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${productInTransit.name}" принят'),
              backgroundColor: AppColors.success,
            ),
          );
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
      }
    }

    actualQuantityController.dispose();
    notesController.dispose();
  }

  Future<void> _showCreateProductInTransitDialog() async {
    _formKey.currentState?.reset();
    _selectedWarehouseId = null;
    _selectedProductTemplateId = null;
    _quantityController.clear();
    _producerController.clear();
    _nameController.clear();
    _shippingLocationController.clear();
    _selectedShippingDate = null;

    final warehousesAsync = ref.read(warehousesProvider);
    // Products будут загружены через Consumer widget

    await showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Создать товар в пути'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  warehousesAsync.when(
                    data: (warehouses) => DropdownButtonFormField<int>(
                      dropdownColor: Colors.white,
                      value: _selectedWarehouseId,
                      hint: const Text('Выберите склад'),
                      onChanged: (value) => setState(() => _selectedWarehouseId = value),
                      validator: (value) => value == null ? 'Выберите склад' : null,
                      items: warehouses.map((warehouse) => DropdownMenuItem(value: warehouse.id, child: Text(warehouse.name))).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Ошибка загрузки складов: $e'),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final productsState = ref.watch(productsProvider);
                      return switch (productsState) {
                        ProductsLoaded(:final products) => DropdownButtonFormField<int>(
                          dropdownColor: Colors.white,
                          value: _selectedProductTemplateId,
                          hint: const Text('Выберите шаблон товара'),
                          onChanged: (value) => setState(() => _selectedProductTemplateId = value),
                          validator: (value) => value == null ? 'Выберите шаблон товара' : null,
                          items: products.data.map((product) => DropdownMenuItem(value: product.id, child: Text(product.name))).toList(),
                        ),
                        ProductsLoading() => const Center(child: CircularProgressIndicator()),
                        ProductsError(:final message) => Text('Ошибка загрузки товаров: $message'),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название товара',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Введите название товара' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите количество';
                      if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Введите корректное число';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _producerController,
                    decoration: InputDecoration(
                      labelText: 'Производитель',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shippingLocationController,
                    decoration: InputDecoration(
                      labelText: 'Место отгрузки',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedShippingDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedShippingDate = pickedDate);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дата отгрузки',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_selectedShippingDate != null ? _formatDate(_selectedShippingDate!) : 'Выберите дату'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final request = CreateProductInTransitRequest(
                    warehouseId: _selectedWarehouseId!,
                    products: [
                      ProductInTransitItemModel(
                        productTemplateId: _selectedProductTemplateId!,
                        quantity: double.parse(_quantityController.text),
                        producer: _producerController.text.isNotEmpty ? _producerController.text : null,
                        name: _nameController.text,
                      ),
                    ],
                    shippingLocation: _shippingLocationController.text.isNotEmpty ? _shippingLocationController.text : null,
                    shippingDate: _selectedShippingDate?.toIso8601String(),
                  );

                  try {
                    await ref.read(productsInTransitProvider.notifier).createProductInTransit(request);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Товар в пути успешно создан'), backgroundColor: AppColors.success),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка создания товара в пути: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Создать', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      });
    });
  }

  String _getProductInTransitStatus(String status) {
    switch (status) {
      case 'in_transit':
        return 'В пути';
      case 'arrived':
        return 'Прибыл';
      case 'received':
        return 'Принят';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.warning;
      case 'arrived':
        return AppColors.info;
      case 'received':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}



