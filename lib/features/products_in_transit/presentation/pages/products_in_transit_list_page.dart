import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';

/// Страница списка товаров в пути
class ProductsInTransitListPage extends ConsumerStatefulWidget {
  const ProductsInTransitListPage({super.key});

  @override
  ConsumerState<ProductsInTransitListPage> createState() => _ProductsInTransitListPageState();
}

class _ProductsInTransitListPageState extends ConsumerState<ProductsInTransitListPage> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  
  // Переменные для фильтра
  int? _selectedProducerId;
  int? _selectedWarehouseId;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    // Загружаем данные при инициализации страницы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    try {
      ref.read(productsInTransitProvider.notifier).loadProductsInTransit();
      // Инициализируем загрузку производителей для фильтра
      ref.read(producersProvider.notifier).loadProducers();
    } catch (e) {
      print('🔴 Ошибка при загрузке данных: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsInTransitProvider);
    // Загружаем производителей и склады для фильтра
    ref.watch(producersProvider);
    ref.watch(warehousesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          
          // Фильтр (показывается при нажатии на иконку фильтра)
          if (_showFilter) _buildFilterSection(),
          
          Expanded(child: _buildProductsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProductDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          // Поле поиска
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _performSearch();
              },
              decoration: InputDecoration(
                hintText: 'Поиск товаров в пути...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                          ref.read(productsInTransitProvider.notifier).refresh();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF007BFF)),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
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
                      _applyFilters();
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
                      _applyFilters();
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
    _applyFilters();
  }

  /// Применить фильтры
  void _applyFilters() {
    // Здесь можно добавить логику фильтрации через провайдер
    // Пока просто обновляем список
    ref.read(productsInTransitProvider.notifier).refresh();
  }

  Widget _buildProductsList() {
    final productsState = ref.watch(productsInTransitProvider);

    return switch (productsState) {
      ProductsInTransitLoading() => const LoadingWidget(),
      ProductsInTransitError(:final message) => _buildErrorState(message),
      ProductsInTransitLoaded(:final products) => _buildLoadedState(products),
    };
  }

  Widget _buildLoadedState(PaginatedResponse<ProductModel> products) {
    // Применяем фильтры
    var filteredProducts = products.data;
    
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsInTransitProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleProductAction('view', product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название товара с меню действий
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Меню действий на уровне названия
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Информация в структурированном виде
              if (product.producerInfo?.name != null) ...[
                _buildInfoRow('Производитель', product.producerInfo!.name!),
              ],
              
              if (product.warehouse?.name != null) ...[
                _buildInfoRow('Склад', product.warehouse!.name!),
              ],
              
              _buildInfoRow('Количество', '${product.quantity.toStringAsFixed(0)} шт.'),
              
              if (product.calculatedVolume != null) ...[
                _buildInfoRow('Объем', '${product.calculatedVolume!.toStringAsFixed(2)} м³'),
              ],
              
              if (product.shippingLocation != null) ...[
                _buildInfoRow('Место отправки', product.shippingLocation!),
              ],
              
              // Статус товара
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.status ?? 'unknown'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(product.status ?? 'unknown'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusTextColor(product.status ?? 'unknown'),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Color(0xFFBDC3C7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет товаров в пути',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Список пуст',
            style: TextStyle(
              color: Color(0xFFBDC3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return AppErrorWidget(
      error: message,
      onRetry: () => ref.read(productsInTransitProvider.notifier).refresh(),
    );
  }

  void _performSearch() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      ref.read(productsInTransitProvider.notifier).refresh();
    } else {
      ref.read(productsInTransitProvider.notifier).searchProducts(_searchQuery!);
    }
  }

  void _showCreateProductDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductInTransitFormPage(),
      ),
    ).then((created) {
      if (created == true) {
        ref.read(productsInTransitProvider.notifier).refresh();
      }
    });
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInTransitFormPage(
              product: product,
              isViewMode: true,
            ),
          ),
        );
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInTransitFormPage(product: product),
          ),
        ).then((updated) {
          if (updated == true) {
            ref.read(productsInTransitProvider.notifier).refresh();
          }
        });
        break;
      case 'delete':
        _showDeleteConfirmationDialog(product);
        break;
    }
  }

  void _showDeleteConfirmationDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар'),
        content: Text('Вы уверены, что хотите удалить товар "${product.name}"? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await ref
          .read(productsInTransitProvider.notifier)
          .deleteProductInTransit(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "${product.name}" удален'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  /// Построение строки информации в стиле поступления товара
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Получить цвет фона для статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'for_receipt':
        return Colors.orange.shade100;
      case 'in_stock':
        return Colors.green.shade100;
      case 'sold':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  /// Получить текст для статуса
  String _getStatusText(String status) {
    switch (status) {
      case 'for_receipt':
        return 'К приемке';
      case 'in_stock':
        return 'В наличии';
      case 'sold':
        return 'Продан';
      default:
        return status;
    }
  }

  /// Получить цвет текста для статуса
  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'for_receipt':
        return Colors.orange.shade800;
      case 'in_stock':
        return Colors.green.shade800;
      case 'sold':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

}
