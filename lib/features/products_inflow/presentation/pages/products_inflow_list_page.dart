import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_form_page.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_detail_page.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/providers/products_inflow_provider.dart';
import 'package:sum_warehouse/features/warehouses/presentation/providers/warehouses_provider.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';
// Удалены импорты компаний/пользователей и dio, т.к. фильтры убраны
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

// Удалены локальные провайдеры компаний и пользователей

/// Страница списка товаров в поступлениях
class ProductsInflowListPage extends ConsumerStatefulWidget {
  const ProductsInflowListPage({super.key});

  @override
  ConsumerState<ProductsInflowListPage> createState() => _ProductsInflowListPageState();
}

class _ProductsInflowListPageState extends ConsumerState<ProductsInflowListPage> {
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
    // Инициализируем загрузку товаров
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsInflowProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsInflowProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilter) _buildFilters(),
          Expanded(child: _buildProductsList(productsState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('🔵 ProductsInflowListPage: Нажата кнопка + (добавить товар)');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                print('🔵 ProductsInflowListPage: Переход к ProductInflowFormPage');
                return const ProductInflowFormPage();
              },
            ),
          ).then((_) {
            print('🔵 ProductsInflowListPage: Возврат из ProductInflowFormPage, обновляем список');
            setState(() {});
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                hintText: 'Поиск по названию, описанию, производителю...',
                prefixIcon: const Icon(Icons.search),
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
                // Поиск с задержкой
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value) {
                    ref.read(productsInflowProvider.notifier).searchProducts(value);
                  }
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

    final filters = ProductInflowFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseId: _selectedWarehouseId,
      producerId: _selectedProducerId,
      arrivalDateFrom: arrivalFromStr,
      arrivalDateTo: arrivalToStr,
      page: 1,
    );
    
    print('🔵 ProductsInflowListPage: Применяем фильтры:');
    print('🔵 - Поиск: ${filters.search}');
    print('🔵 - Склад: ${filters.warehouseId}');
    print('🔵 - Производитель: ${filters.producerId}');
    print('🔵 - Дата от: ${filters.arrivalDateFrom}');
    print('🔵 - Дата до: ${filters.arrivalDateTo}');
    print('🔵 - Параметры запроса: ${filters.toQueryParams()}');
    
    ref.read(productsInflowProvider.notifier).filterProducts(filters);
  }

  Widget _buildProductsList(ProductsInflowState state) {
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
              'Ошибка загрузки товаров',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(productsInflowProvider.notifier).refresh();
              },
              child: const Text('Попробовать снова'),
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
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Товары не найдены',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Попробуйте изменить фильтры поиска',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(productsInflowProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.data.length + 1, // +1 для индикатора загрузки
            itemBuilder: (context, index) {
              if (index == products.data.length) {
                // Показать индикатор загрузки если есть следующая страница
                final hasNextPage = products.pagination?.currentPage != null && 
                    products.pagination!.currentPage < products.pagination!.lastPage;
                
                if (hasNextPage) {
                  // Загружаем следующую страницу
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(productsInflowProvider.notifier).loadNextPage();
                  });
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }

              final product = products.data[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductInflowModel product) {
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
              _buildInfoRow('Дата поступления', product.arrivalDate != null ? _formatDate(product.arrivalDate!) : 'Не указана'),
              
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_stock':
        return Colors.green;
      case 'for_receipt':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_stock':
        return 'На складе';
      case 'for_receipt':
        return 'На приемке';
      case 'in_transit':
        return 'В пути';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
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
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (correctionStatus) {
      case 'correction':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        statusText = 'Требует внимание';
        icon = Icons.warning;
        break;
      case 'revised':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        statusText = 'Внесена корректировка';
        icon = Icons.edit_note;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        statusText = correctionStatus;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openProductDetail(ProductInflowModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductInflowDetailPage(product: product),
      ),
    );
  }

  void _handleProductAction(String action, ProductInflowModel product) {
    switch (action) {
      case 'view':
        _openProductDetail(product);
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInflowFormPage(product: product),
          ),
        );
        break;
      case 'delete':
        _confirmDeleteProduct(product);
        break;
    }
  }

  void _confirmDeleteProduct(ProductInflowModel product) {
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
                await ref.read(productsInflowProvider.notifier).deleteProduct(product.id);
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

  void _handleMenuAction(String action, ProductInflowModel product) {
    print('🔵 ProductsInflowListPage: Выбрано действие "$action" для товара ID: ${product.id}');
    
    switch (action) {
      case 'preview':
        print('🔵 ProductsInflowListPage: Переход к превью товара ID: ${product.id}');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInflowDetailPage(product: product),
          ),
        );
        break;
        
      case 'edit':
        print('🔵 ProductsInflowListPage: Переход к редактированию товара ID: ${product.id}');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductInflowFormPage(product: product),
          ),
        ).then((_) {
          print('🔵 ProductsInflowListPage: Возврат из редактирования, обновляем список');
          ref.read(productsInflowProvider.notifier).refresh();
        });
        break;
        
      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  void _showDeleteDialog(ProductInflowModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление товара'),
        content: Text('Вы уверены, что хотите удалить товар "${product.name ?? 'Без названия'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              print('🔵 ProductsInflowListPage: Удаляем товар ID: ${product.id}');
              
              try {
                await ref.read(productsInflowProvider.notifier).deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Товар успешно удален')),
                  );
                }
              } catch (e) {
                print('🔴 ProductsInflowListPage: Ошибка удаления товара: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка удаления товара: $e')),
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
