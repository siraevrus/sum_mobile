import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/inventory_stocks_provider.dart';
import '../widgets/inventory_filter_widget.dart';

/// Основная страница раздела "Поступление товара" с поиском и фильтром
class InventoryMainPage extends ConsumerStatefulWidget {
  const InventoryMainPage({super.key});

  @override
  ConsumerState<InventoryMainPage> createState() => _InventoryMainPageState();
}

class _InventoryMainPageState extends ConsumerState<InventoryMainPage> {
  final TextEditingController _searchController = TextEditingController();
  InventoryFilter _currentFilter = const InventoryFilter();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStocks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStocks() {
    ref.read(inventoryStocksProvider.notifier).loadStocks(
      warehouseId: _currentFilter.warehouseId,
    );
  }

  void _onFilterChanged(InventoryFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    _loadStocks();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products;

    // Фильтрация по поиску
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
               (product.producerInfo?.name?.toLowerCase().contains(_searchQuery) ?? false) ||
               (product.warehouse?.name?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Фильтрация по компании (клиентская)
    if (_currentFilter.companyId != null) {
      filtered = filtered.where((product) {
        return product.warehouse?.companyId == _currentFilter.companyId;
      }).toList();
    }

    // Фильтрация по датам (клиентская)
    if (_currentFilter.dateFrom != null || _currentFilter.dateTo != null) {
      filtered = filtered.where((product) {
        final arrivalDate = product.arrivalDate;
        if (arrivalDate == null) return false;

        if (_currentFilter.dateFrom != null && 
            arrivalDate.isBefore(_currentFilter.dateFrom!)) {
          return false;
        }

        if (_currentFilter.dateTo != null && 
            arrivalDate.isAfter(_currentFilter.dateTo!.add(const Duration(days: 1)))) {
          return false;
        }

        return true;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final stocksState = ref.watch(inventoryStocksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Поиск и фильтр
          _buildSearchAndFilter(),
          
          // Активные фильтры
          if (_currentFilter.hasActiveFilters || _searchQuery.isNotEmpty)
            _buildActiveFilters(),
          
          // Список товаров
          Expanded(
            child: _buildStocksContent(stocksState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск товаров...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          InventoryFilterWidget(
            currentFilter: _currentFilter,
            onFilterChanged: _onFilterChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final List<Widget> filterChips = [];

    if (_searchQuery.isNotEmpty) {
      filterChips.add(
        Chip(
          label: Text('Поиск: $_searchQuery'),
          onDeleted: () {
            _searchController.clear();
            _onSearchChanged('');
          },
        ),
      );
    }

    if (_currentFilter.warehouseId != null) {
      final warehousesAsync = ref.watch(inventoryWarehousesProvider);
      warehousesAsync.whenData((warehouses) {
        final warehouse = warehouses.firstWhere(
          (w) => w.id == _currentFilter.warehouseId,
          orElse: () => throw StateError('Warehouse not found'),
        );
        filterChips.add(
          Chip(
            label: Text('Склад: ${warehouse.name}'),
            onDeleted: () {
              _onFilterChanged(_currentFilter.copyWith(clearWarehouse: true));
            },
          ),
        );
      });
    }

    if (_currentFilter.companyId != null) {
      final companiesAsync = ref.watch(inventoryCompaniesProvider);
      companiesAsync.whenData((companies) {
        final company = companies.firstWhere(
          (c) => c.id == _currentFilter.companyId,
          orElse: () => throw StateError('Company not found'),
        );
        filterChips.add(
          Chip(
            label: Text('Компания: ${company.name}'),
            onDeleted: () {
              _onFilterChanged(_currentFilter.copyWith(clearCompany: true));
            },
          ),
        );
      });
    }

    if (_currentFilter.dateFrom != null) {
      filterChips.add(
        Chip(
          label: Text('От: ${_formatDate(_currentFilter.dateFrom!)}'),
          onDeleted: () {
            _onFilterChanged(_currentFilter.copyWith(clearDateFrom: true));
          },
        ),
      );
    }

    if (_currentFilter.dateTo != null) {
      filterChips.add(
        Chip(
          label: Text('До: ${_formatDate(_currentFilter.dateTo!)}'),
          onDeleted: () {
            _onFilterChanged(_currentFilter.copyWith(clearDateTo: true));
          },
        ),
      );
    }

    if (filterChips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Активные фильтры:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: filterChips,
          ),
        ],
      ),
    );
  }

  Widget _buildStocksContent(InventoryStocksState state) {
    switch (state) {
      case InventoryStocksLoading():
        return const LoadingWidget();
      case InventoryStocksError():
        return _buildErrorState(state.message);
      case InventoryStocksLoaded():
        final filteredStocks = _filterProducts(state.stocks);
        
        if (filteredStocks.isEmpty) {
          return _buildEmptyState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            _loadStocks();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredStocks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildStockCard(filteredStocks[index]);
            },
          ),
        );
    }
  }

  Widget _buildStockCard(ProductModel stock) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stock.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            if (stock.warehouse != null && stock.warehouse!.name != null) ...[
              _buildInfoRow('Склад', stock.warehouse!.name!),
            ],
            
            if (stock.producerInfo != null && stock.producerInfo!.name != null) ...[
              _buildInfoRow('Производитель', stock.producerInfo!.name!),
            ],
            
            _buildInfoRow('Количество', '${stock.quantity.toStringAsFixed(0)} шт.'),
            
            if (stock.calculatedVolume != null) ...[
              _buildInfoRow('Объем', '${stock.calculatedVolume!.toStringAsFixed(2)} м³'),
            ],
            
            if (stock.arrivalDate != null) ...[
              _buildInfoRow('Дата поступления', _formatDate(stock.arrivalDate!)),
            ],
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stock.status == 'in_stock' ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stock.status == 'in_stock' ? 'В наличии' : stock.status ?? 'Неизвестно',
                    style: TextStyle(
                      fontSize: 12,
                      color: stock.status == 'in_stock' ? Colors.green.shade800 : Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Статус корректировки
                if (stock.correctionStatus != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCorrectionStatusColor(stock.correctionStatus!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCorrectionStatusText(stock.correctionStatus!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCorrectionStatusTextColor(stock.correctionStatus!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStocks,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Товары не найдены',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Попробуйте изменить параметры поиска или фильтра',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Получить цвет фона для статуса корректировки
  Color _getCorrectionStatusColor(String status) {
    switch (status) {
      case 'revised':
        return Colors.red.shade100; // Красный фон для "Требует корректировки"
      case 'correction':
        return Colors.yellow.shade100; // Желтый фон для "Учтена корректировка"
      default:
        return Colors.grey.shade100;
    }
  }

  /// Получить текст для статуса корректировки
  String _getCorrectionStatusText(String status) {
    switch (status) {
      case 'revised':
        return 'Требует корректировки';
      case 'correction':
        return 'Учтена корректировка';
      default:
        return status;
    }
  }

  /// Получить цвет текста для статуса корректировки
  Color _getCorrectionStatusTextColor(String status) {
    switch (status) {
      case 'revised':
        return Colors.red.shade800; // Красный текст
      case 'correction':
        return Colors.yellow.shade800; // Темно-желтый текст
      default:
        return Colors.grey.shade800;
    }
  }
}
