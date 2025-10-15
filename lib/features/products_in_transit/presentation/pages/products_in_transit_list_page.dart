import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/product_in_transit_detail_page.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
// Удалены импорты компаний/пользователей и dio, т.к. фильтры убраны
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

// Удалены локальные провайдеры компаний и пользователей

/// Страница списка товаров в пути
class ProductsInTransitListPage extends ConsumerStatefulWidget {
  const ProductsInTransitListPage({super.key});

  @override
  ConsumerState<ProductsInTransitListPage> createState() => _ProductsInTransitListPageState();
}

class _ProductsInTransitListPageState extends ConsumerState<ProductsInTransitListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Переменные для фильтра
  int? _selectedWarehouseId;
  int? _selectedProducerId;
  DateTime? _arrivalDateFrom;
  DateTime? _arrivalDateTo;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsInTransitProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _createProduct,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Фильтры
          if (_showFilter) _buildFilters(),
          
          // Список товаров
          Expanded(
            child: _buildProductsList(productsState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
        color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск товаров в пути...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
        color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Сбросить',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedWarehouseId,
                  decoration: InputDecoration(
                    labelText: 'Склад',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все склады')),
                    ...ref.watch(warehousesProvider).when(
                      data: (warehouses) => warehouses.map((warehouse) => DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(warehouse.name),
                      )).toList(),
                      loading: () => [],
                      error: (e, st) => [],
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWarehouseId = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedProducerId,
                  decoration: InputDecoration(
                    labelText: 'Производитель',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все производители')),
                    ...ref.watch(producersProvider).when(
                      data: (producers) => producers.map((producer) => DropdownMenuItem(
                          value: producer.id,
                          child: Text(producer.name),
                      )).toList(),
                      loading: () => [],
                      error: (e, st) => [],
                    ),
                  ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProducerId = value;
                      });
                      _applyFilters();
                    },
                  ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Вторая строка фильтров: Дата от - Дата до
          Row(
                children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _arrivalDateFrom = picked;
                      });
                      _applyFilters();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Дата от',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      _arrivalDateFrom != null
                          ? '${_arrivalDateFrom!.day.toString().padLeft(2, '0')}.${_arrivalDateFrom!.month.toString().padLeft(2, '0')}.${_arrivalDateFrom!.year}'
                          : 'Не выбрана',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _arrivalDateTo = picked;
                      });
                      _applyFilters();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Дата до',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      _arrivalDateTo != null
                          ? '${_arrivalDateTo!.day.toString().padLeft(2, '0')}.${_arrivalDateTo!.month.toString().padLeft(2, '0')}.${_arrivalDateTo!.year}'
                          : 'Не выбрана',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedWarehouseId = null;
      _selectedProducerId = null;
      _arrivalDateFrom = null;
      _arrivalDateTo = null;
    });
    _applyFilters();
  }

  void _applyFilters() {
    // Формируем параметры дат (yyyy-MM-dd)
    String? arrivalFromStr = _arrivalDateFrom != null
        ? '${_arrivalDateFrom!.year.toString().padLeft(4, '0')}-${_arrivalDateFrom!.month.toString().padLeft(2, '0')}-${_arrivalDateFrom!.day.toString().padLeft(2, '0')}'
        : null;
    String? arrivalToStr = _arrivalDateTo != null
        ? '${_arrivalDateTo!.year.toString().padLeft(4, '0')}-${_arrivalDateTo!.month.toString().padLeft(2, '0')}-${_arrivalDateTo!.day.toString().padLeft(2, '0')}'
        : null;

    final filters = ProductInTransitFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseId: _selectedWarehouseId,
      producerId: _selectedProducerId,
      arrivalDateFrom: arrivalFromStr,
      arrivalDateTo: arrivalToStr,
      page: 1,
    );
    
    
    ref.read(productsInTransitProvider.notifier).filterProducts(filters);
  }

  Widget _buildProductsList(ProductsInTransitState state) {
    return state.when(
      loading: () => const Center(child: LoadingWidget()),
      error: (message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки товаров в пути',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(productsInTransitProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      loaded: (products, filters) {
        if (products.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Товары в пути не найдены',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Попробуйте изменить фильтры поиска',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
    }

    return RefreshIndicator(
          onRefresh: () async {
            await ref.read(productsInTransitProvider.notifier).refresh();
          },
          child: ListView.separated(
        padding: const EdgeInsets.all(16),
            itemCount: products.data.length + 1, // +1 для кнопки "Загрузить еще"
            separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
              if (index == products.data.length) {
                // Кнопка "Загрузить еще"
                final currentPage = products.pagination?.currentPage ?? 1;
                final lastPage = products.pagination?.lastPage ?? 1;
                
                if (currentPage < lastPage) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(productsInTransitProvider.notifier).loadNextPage();
                        },
                        child: const Text('Загрузить еще'),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final product = products.data[index];
          return _buildProductCard(product);
        },
      ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductInTransitModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с меню
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name ?? 'Без названия',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleProductAction(value, product),
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
              const SizedBox(height: 12),
              
              // Информация о товаре
              _buildInfoRow('Количество', product.quantity),
              _buildInfoRow('Объем', '${_formatVolume(product.calculatedVolume)} ${product.template?.unit ?? ''}'),
              _buildInfoRow('Склад', product.warehouse?.name ?? 'Не указан'),
              _buildInfoRow('Место отгрузки', product.shippingLocation ?? 'Не указано'),
              _buildInfoRow('Дата отгрузки', _formatDate(product.shippingDate)),
              _buildInfoRow('Ожидаемая дата прибытия', _formatDate(product.expectedArrivalDate)),
              
              // Тег статуса коррекции
              if (product.correctionStatus != null) ...[
                const SizedBox(height: 8),
                _buildCorrectionStatusTag(product.correctionStatus!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'Не указана') {
      return 'Не указана';
    }
    
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    } catch (e) {
      return dateString; // Возвращаем исходное значение если не удалось распарсить
    }
  }

  String _formatVolume(String? volumeString) {
    if (volumeString == null || volumeString.isEmpty || volumeString == 'Не рассчитан') {
      return 'Не рассчитан';
    }

    try {
      final volume = double.parse(volumeString);
      return volume.toStringAsFixed(3);
    } catch (e) {
      return volumeString; // Возвращаем исходное значение если не удалось распарсить
    }
  }

  Widget _buildCorrectionStatusTag(String correctionStatus) {
    Color tagColor;
    String tagText;
    
    switch (correctionStatus) {
      case 'correction':
        tagColor = Colors.red;
        tagText = 'Требует внимание';
        break;
      case 'revised':
        tagColor = Colors.orange;
        tagText = 'Внесена корректировка';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withOpacity(0.3)),
      ),
      child: Text(
        tagText,
        style: TextStyle(
          color: tagColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openProductDetail(ProductInTransitModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductInTransitDetailPage(product: product),
      ),
    );
  }

  void _createProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductInTransitFormPage(),
      ),
    );
  }

  void _handleProductAction(String action, ProductInTransitModel product) {
    switch (action) {
      case 'view':
        _openProductDetail(product);
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInTransitFormPage(product: product),
          ),
        );
        break;
      case 'delete':
        _confirmDeleteProduct(product);
        break;
    }
  }

  void _confirmDeleteProduct(ProductInTransitModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление товара'),
        content: Text('Вы уверены, что хотите удалить товар "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(productsInTransitProvider.notifier).deleteProduct(product.id);
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
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
