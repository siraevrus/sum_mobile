import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products/presentation/providers/products_provider.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/features/products/presentation/pages/product_form_page.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Страница списка товаров
class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Переменные для фильтра
  int? _selectedProducerId;
  int? _selectedWarehouseId;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем загрузку производителей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(producersProvider.notifier).loadProducers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    // Загружаем производителей и склады для фильтра
    ref.watch(producersProvider);
    ref.watch(warehousesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Поиск и кнопка добавления
          _buildSearchAndAddSection(),
          
          // Фильтр (показывается при нажатии на иконку фильтра)
          if (_showFilter) _buildFilterSection(),
          
          // Список товаров
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(productsProvider.notifier).loadProducts();
              },
              child: switch (productsAsync) {
                ProductsLoaded(products: final products) => _buildProductsList(products.data),
                ProductsLoading() => const Center(child: CircularProgressIndicator()),
                ProductsError(message: final error) => AppErrorWidget(
                  error: error,
                  onRetry: () => ref.read(productsProvider.notifier).loadProducts(),
                ),
                ProductsInitial() => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductFormPage(),
            ),
          ).then((_) => ref.read(productsProvider.notifier).loadProducts());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndAddSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Поле поиска
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск товаров...',
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
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // Иконка фильтра
          Container(
            decoration: BoxDecoration(
              color: _showFilter ? AppColors.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showFilter ? AppColors.primary : const Color(0xFFE0E0E0),
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showFilter = !_showFilter;
                });
              },
              icon: Icon(
                _showFilter ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilter ? Colors.white : Colors.grey.shade600,
              ),
              tooltip: 'Фильтр',
            ),
          ),
        ],
      ),
    );
  }

  /// Виджет секции фильтра
  Widget _buildFilterSection() {
    final producersAsync = ref.watch(producersProvider);
    final warehousesAsync = ref.watch(warehousesProvider);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE0E0E0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20, color: Color(0xFF6C757D)),
              const SizedBox(width: 8),
              const Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              // Кнопка сброса фильтров
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Сбросить',
                  style: TextStyle(color: Color(0xFF6C757D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              // Фильтр по производителю
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Производитель',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF495057),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedProducerId,
                    decoration: InputDecoration(
                      hintText: 'Все производители',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: producersAsync.when(
                      data: (producers) => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Все производители'),
                        ),
                        ...producers.map((producer) => DropdownMenuItem<int>(
                          value: producer.id,
                          child: Text(producer.name),
                        )),
                      ],
                      loading: () => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Загрузка...'),
                        ),
                      ],
                      error: (_, __) => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Ошибка загрузки'),
                        ),
                      ],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedProducerId = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Фильтр по складу
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Склад',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF495057),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedWarehouseId,
                    decoration: InputDecoration(
                      hintText: 'Все склады',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: warehousesAsync.when(
                      data: (warehouses) => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Все склады'),
                        ),
                        ...warehouses.map((warehouse) => DropdownMenuItem<int>(
                          value: warehouse.id,
                          child: Text(warehouse.name),
                        )),
                      ],
                      loading: () => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Загрузка...'),
                        ),
                      ],
                      error: (_, __) => [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Ошибка загрузки'),
                        ),
                      ],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedWarehouseId = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Сбросить все фильтры
  void _clearFilters() {
    setState(() {
      _selectedProducerId = null;
      _selectedWarehouseId = null;
    });
  }

  Widget _buildProductsList(List<ProductModel> products) {
    // Применяем фильтры
    var filteredProducts = products;
    
    // Фильтр по поиску
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) => 
        (p.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Фильтр по производителю
    if (_selectedProducerId != null) {
      filteredProducts = filteredProducts.where((p) => 
        p.producerId == _selectedProducerId
      ).toList();
    }
    
    // Фильтр по складу
    if (_selectedWarehouseId != null) {
      filteredProducts = filteredProducts.where((p) => 
        p.warehouse?.id == _selectedWarehouseId
      ).toList();
    }
    
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Товары не найдены'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductFormPage(
              product: _convertToEntity(product),
              isViewMode: true,
            ),
          ),
        ).then((_) => ref.read(productsProvider.notifier).loadProducts()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок товара с меню
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name ?? 'Без названия',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleProductAction(action, product),
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF6C757D),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Производитель: значение (в одну строку, значение — жирное)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Производитель: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: _getProducerName(product),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Склад: значение (в одну строку, значение — жирное)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Склад: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: _getWarehouseName(product),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Объем: значение (в одну строку, значение — жирное)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Объем: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '${product.calculatedVolume ?? 0} ${product.template?.unit ?? 'м³'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductFormPage(
              product: _convertToEntity(product),
              isViewMode: true,
            ),
          ),
        ).then((_) => ref.read(productsProvider.notifier).loadProducts());
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductFormPage(
              product: _convertToEntity(product),
              isViewMode: false,
            ),
          ),
        ).then((_) => ref.read(productsProvider.notifier).loadProducts());
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, product);
        break;
    }
  }

  /// Показать диалог подтверждения удаления
  void _showDeleteConfirmDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить товар "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Удалить товар через API
  void _deleteProduct(int productId) async {
    try {
      final dataSource = ref.read(productsApiDataSourceProvider);
      await dataSource.deleteProduct(productId);
      
      // Обновляем список товаров
      await ref.read(productsProvider.notifier).loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Конвертировать ProductModel в ProductEntity для формы
  ProductEntity _convertToEntity(ProductModel model) {
    return ProductEntity(
      id: model.id,
      name: model.name,
      productTemplateId: model.template?.id ?? 0,
      warehouseId: model.warehouse?.id ?? 0,
      creatorId: model.creator?.id ?? 0,
      quantity: model.quantity,
      description: model.description,
      notes: model.notes,
      producer: _getProducerName(model),
      attributes: model.attributes ?? {},
      calculatedValue: model.calculatedVolume,
      transportNumber: model.transportNumber,
      arrivalDate: model.arrivalDate,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Получить имя производителя
  String _getProducerName(ProductModel product) {
    // 1. Проверяем связанный объект producer из API include
    if (product.producerInfo?.name != null && product.producerInfo!.name!.isNotEmpty) {
      return product.producerInfo!.name!;
    }
    
    // 2. Проверяем producer_id и пытаемся найти по ID в загруженных producers
    if (product.producerId != null) {
      final producersAsync = ref.read(producersProvider);
      if (producersAsync.hasValue) {
        final producers = producersAsync.asData?.value ?? [];
        try {
          final producer = producers.firstWhere((p) => p.id == product.producerId);
          return producer.name;
        } catch (e) {
          // Производитель не найден в списке
        }
      }
    }
    
    // 3. Fallback - возвращаем "Не указан"
    
    return 'Не указан';
  }
  
  /// Получить имя склада
  String _getWarehouseName(ProductModel product) {
    // Проверяем связанный объект warehouse из API include
    if (product.warehouse?.name != null && product.warehouse!.name!.isNotEmpty) {
      return product.warehouse!.name!;
    }
    
    return 'Не указан';
  }
}

/// Чип с информацией
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6C757D),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF495057),
            ),
          ),
        ],
      ),
    );
  }
}
