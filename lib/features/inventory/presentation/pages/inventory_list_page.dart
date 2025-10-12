import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';
import 'package:sum_warehouse/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/stock_movement_form_page.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Экран списка остатков товаров
class InventoryListPage extends ConsumerStatefulWidget {
  const InventoryListPage({super.key});

  @override
  ConsumerState<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends ConsumerState<InventoryListPage> {
  final _searchController = TextEditingController();
  String? _selectedProducer;
  int? _selectedWarehouseId;
  bool? _filterLowStock;
  StockStatus? _filterStatus;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StockMovementFormPage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Создать движение товара',
      ),
      
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Активные фильтры
          if (_hasActiveFilters()) _buildActiveFilters(),
          
          // Контент с остатками
          Expanded(
            child: stocksAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (stocks) => RefreshIndicator(
                onRefresh: () async {
                  await ref.read(stocksListProvider.notifier).refresh();
                },
                child: Column(
                  children: [
                    // Сводка по остаткам
                    _buildSummaryCards(stocks),
                    
                    // Список остатков
                    Expanded(
                      child: stocks.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: stocks.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final stock = stocks[index];
                                return _buildStockCard(stock);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по названию товара...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
        onChanged: (value) {
          // TODO: Реализовать поиск с задержкой
        },
      ),
    );
  }
  
  bool _hasActiveFilters() {
    return _filterStatus != null || 
           _filterLowStock != null || 
           _selectedWarehouseId != null || 
           _selectedProducer != null;
  }
  
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_filterStatus != null)
                  _buildFilterChip(_filterStatus!.displayName, () => setState(() => _filterStatus = null)),
                if (_filterLowStock == true)
                  _buildFilterChip('Мало остатков', () => setState(() => _filterLowStock = null)),
                if (_selectedWarehouseId != null)
                  _buildFilterChip('Склад #$_selectedWarehouseId', () => setState(() => _selectedWarehouseId = null)),
                if (_selectedProducer != null)
                  _buildFilterChip('Производитель: $_selectedProducer', () => setState(() => _selectedProducer = null)),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIconColor: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
  
  void _clearAllFilters() {
    setState(() {
      _filterStatus = null;
      _filterLowStock = null;
      _selectedWarehouseId = null;
      _selectedProducer = null;
    });
  }
  
  Widget _buildSummaryCards(List<StockModel> stocks) {
    final inStock = stocks.where((s) => s.stockStatus == StockStatus.inStock).length;
    final lowStock = stocks.where((s) => s.stockStatus == StockStatus.lowStock).length;
    final outOfStock = stocks.where((s) => s.stockStatus == StockStatus.outOfStock).length;
    final totalVolume = stocks.fold<double>(0.0, (sum, s) => sum + s.availableVolume);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'В наличии',
              inStock.toString(),
              AppColors.success,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Мало',
              lowStock.toString(),
              AppColors.warning,
              Icons.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Нет в наличии',
              outOfStock.toString(),
              AppColors.error,
              Icons.error,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStockCard(StockModel stock) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleStockAction('view', stock),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                stock.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Информация о товаре
              _buildInfoRow('Производитель', stock.producer.isNotEmpty ? stock.producer : 'Не указан'),
              _buildInfoRow('Склад', stock.warehouse?.name ?? 'Склад #${stock.warehouseId}'),
              _buildInfoRow('Доступно', '${stock.availableQuantity.toStringAsFixed(0)} шт.'),
              _buildInfoRow('Объем', stock.availableVolume > 0 ? '${stock.availableVolume.toStringAsFixed(3)} м³' : 'Не рассчитан'),
              _buildInfoRow('Зарезервировано', '${stock.reservedQuantity.toStringAsFixed(0)} шт.'),
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
  
  IconData _getStatusIcon(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return Icons.check_circle;
      case StockStatus.lowStock:
        return Icons.warning;
      case StockStatus.outOfStock:
        return Icons.cancel;
    }
  }
  
  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.error;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Сегодня';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн назад';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры остатков'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статус остатков
              const Text('Статус остатков:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final status in [null, ...StockStatus.values])
                    FilterChip(
                      label: Text(status?.displayName ?? 'Все'),
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = selected ? status : null;
                        });
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Мало остатков'),
                value: _filterLowStock ?? false,
                onChanged: (value) {
                  setState(() {
                    _filterLowStock = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearAllFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Очистить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
  
  void _showAnalytics() {
    // TODO: Показать аналитику остатков
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Аналитика остатков - в разработке')),
    );
  }
  
  /// Построить состояние ошибки
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Ошибка загрузки остатков',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(stocksListProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Построить пустое состояние
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Нет данных об остатках',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Создайте первое движение товара или измените фильтры',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Обработчик действий с остатками
  void _handleStockAction(String action, StockModel stock) {
    switch (action) {
      case 'view':
        // TODO: Перейти к деталям остатка
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Просмотр остатка "${stock.name}"')),
        );
        break;
      case 'movement':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const StockMovementFormPage(),
          ),
        ).then((_) => ref.read(stocksListProvider.notifier).refresh());
        break;
      case 'adjust':
        _showAdjustStockDialog(stock);
        break;
      default:
        break;
    }
  }
  
  void _showAdjustStockDialog(StockModel stock) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Корректировка остатков'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Товар: ${stock.name}'),
            Text('Текущее количество: ${stock.availableQuantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Новое количество',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина корректировки',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Реализовать корректировку остатков
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Остатки скорректированы'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}


