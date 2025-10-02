import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_form_page.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_detail_page.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/providers/products_inflow_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductInflowFormPage(),
            ),
          ).then((_) => setState(() {}));
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
          Text(
            'Фильтры',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
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
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все склады')),
                    DropdownMenuItem(value: 1, child: Text('Основной склад')),
                    DropdownMenuItem(value: 2, child: Text('Склад №2')),
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
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все производители')),
                    DropdownMenuItem(value: 1, child: Text('ООО Лесопилка')),
                    DropdownMenuItem(value: 2, child: Text('Лесозавод №1')),
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
        ],
      ),
    );
  }

  void _applyFilters() {
    final filters = ProductInflowFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseId: _selectedWarehouseId,
      producerId: _selectedProducerId,
      page: 1,
    );
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
                final hasNextPage = products.pagination.currentPage < products.pagination.lastPage;
                
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductInflowDetailPage(product: product),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с названием и статусом
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(product.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(product.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(product.status),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Описание
                if (product.description != null && product.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                
                // Информация о товаре
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.inventory,
                        label: 'Количество',
                        value: '${product.quantity} ${product.template?.unit ?? ''}',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calculate,
                        label: 'Объем',
                        value: product.calculatedVolume ?? '0',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.warehouse,
                        label: 'Склад',
                        value: product.warehouse?.name ?? 'Не указан',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.factory,
                        label: 'Производитель',
                        value: product.producer?.name ?? 'Не указан',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.person,
                        label: 'Создатель',
                        value: product.creator?.name ?? 'Не указан',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today,
                        label: 'Дата поступления',
                        value: product.arrivalDate != null 
                            ? _formatDate(product.arrivalDate!)
                            : 'Не указана',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
}
