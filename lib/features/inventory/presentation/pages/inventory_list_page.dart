import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';
import 'package:sum_warehouse/features/inventory/data/datasources/inventory_remote_datasource.dart';
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
  
  List<StockModel> _stocks = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadStocks();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final dataSource = ref.read(inventoryRemoteDataSourceProvider);
      final stocks = await dataSource.getStocks();
      
      setState(() {
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);

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
            child: inventoryAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (inventory) => RefreshIndicator(
                onRefresh: () async {
                  await ref.read(inventoryListProvider.notifier).refresh();
                },
                child: Column(
                  children: [
                    // Сводка по остаткам
                    _buildSummaryCards(inventory),
                    
                    // Список остатков
                    Expanded(
                      child: inventory.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: inventory.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = inventory[index];
                                return _buildInventoryCard(item);
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
           _filterNeedsRestock != null || 
           _selectedWarehouseId != null;
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
                if (_filterNeedsRestock == true)
                  _buildFilterChip('Нужна закупка', () => setState(() => _filterNeedsRestock = null)),
                if (_selectedWarehouseId != null)
                  _buildFilterChip('Склад #$_selectedWarehouseId', () => setState(() => _selectedWarehouseId = null)),
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
      _filterNeedsRestock = null;
      _selectedWarehouseId = null;
    });
  }
  
  Widget _buildSummaryCards(List<InventoryEntity> inventory) {
    final inStock = inventory.where((i) => i.stockStatus == StockStatus.inStock).length;
    final lowStock = inventory.where((i) => i.stockStatus == StockStatus.lowStock).length;
    final outOfStock = inventory.where((i) => i.stockStatus == StockStatus.outOfStock).length;
    
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
  
  Widget _buildInventoryCard(InventoryEntity inventory) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(inventory.stockStatus).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleInventoryAction('view', inventory),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inventory.product?.name ?? 'Товар #${inventory.productId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Статус остатков
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(inventory.stockStatus).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          inventory.stockStatus.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(inventory.stockStatus),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Меню действий
                      PopupMenuButton<String>(
                        onSelected: (action) => _handleInventoryAction(action, inventory),
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
                            value: 'movement',
                            child: Row(
                              children: [
                                Icon(Icons.swap_vert, size: 20),
                                SizedBox(width: 8),
                                Text('Движение'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'adjust',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Корректировка'),
                              ],
                            ),
                          ),
                          if (inventory.needsRestock)
                            const PopupMenuItem(
                              value: 'restock',
                              child: Row(
                                children: [
                                  Icon(Icons.add_shopping_cart, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Заказать', style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Склад
              Row(
                children: [
                  Icon(Icons.warehouse, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    inventory.warehouse?.name ?? 'Склад #${inventory.warehouseId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Количества
              Row(
                children: [
                  // Общее количество
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${inventory.quantity.toStringAsFixed(0)} ${inventory.product?.unit ?? 'шт'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Доступно
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '${inventory.availableQuantity.toStringAsFixed(0)} доступно',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (inventory.reservedQuantity > 0) ...[
                    const SizedBox(width: 8),
                    // Зарезервировано
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${inventory.reservedQuantity.toStringAsFixed(0)} резерв',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              // Уровни остатков
              if (inventory.minStockLevel != null || inventory.maxStockLevel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (inventory.minStockLevel != null) ...[
                      Text(
                        'Мин: ${inventory.minStockLevel!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (inventory.maxStockLevel != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Макс: ${inventory.maxStockLevel!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    if (inventory.fillPercentage != null) ...[
                      Text(
                        '${inventory.fillPercentage!.toStringAsFixed(0)}% заполнено',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Рекомендация по закупке
              if (inventory.needsRestock && inventory.recommendedRestockQuantity != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Рекомендуется заказать: ${inventory.recommendedRestockQuantity!.toStringAsFixed(0)} ${inventory.product?.unit ?? 'шт'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Дата последнего движения
              if (inventory.lastMovementDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Последнее движение: ${_formatDate(inventory.lastMovementDate!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                title: const Text('Нужна закупка'),
                value: _filterNeedsRestock ?? false,
                onChanged: (value) {
                  setState(() {
                    _filterNeedsRestock = value;
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
            onPressed: () => ref.invalidate(inventoryListProvider),
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
  
  void _showAdjustStockDialog(InventoryEntity inventory) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Корректировка остатков'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Товар: ${inventory.product?.name}'),
            Text('Текущее количество: ${inventory.quantity}'),
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
  
  void _createRestockRequest(InventoryEntity inventory) {
    // TODO: Создать запрос на пополнение
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Создан запрос на пополнение "${inventory.product?.name}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  List<InventoryEntity> _getMockInventory() {
    return [
      const InventoryEntity(
        id: 1,
        warehouseId: 1,
        productId: 1,
        quantity: 150,
        reservedQuantity: 20,
        availableQuantity: 130,
        minStockLevel: 50,
        maxStockLevel: 200,
        lastMovementDate: null,
        warehouse: WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
        product: ProductEntity(
          id: 1,
          name: 'Доска обрезная 150x25x6000',
          productTemplateId: 1,
          unit: 'м³',
          producer: 'ООО "СтройМатериалы"',
        ),
      ),
      const InventoryEntity(
        id: 2,
        warehouseId: 2,
        productId: 2,
        quantity: 15, // Мало остатков
        reservedQuantity: 5,
        availableQuantity: 10,
        minStockLevel: 100,
        maxStockLevel: 500,
        lastMovementDate: null,
        warehouse: WarehouseEntity(
          id: 2,
          name: 'Склад №2',
          address: 'ул. Промышленная, 5',
          companyId: 1,
        ),
        product: ProductEntity(
          id: 2,
          name: 'Кирпич керамический полнотелый',
          productTemplateId: 2,
          unit: 'шт',
          producer: 'Кирпичный завод "Керам"',
        ),
      ),
      const InventoryEntity(
        id: 3,
        warehouseId: 1,
        productId: 3,
        quantity: 0, // Нет в наличии
        reservedQuantity: 0,
        availableQuantity: 0,
        minStockLevel: 20,
        maxStockLevel: 100,
        lastMovementDate: null,
        warehouse: WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
        product: ProductEntity(
          id: 3,
          name: 'Цемент портландский М400',
          productTemplateId: 3,
          unit: 'мешок',
          producer: 'Цементный комбинат',
        ),
      ),
      const InventoryEntity(
        id: 4,
        warehouseId: 1,
        productId: 4,
        quantity: 80,
        reservedQuantity: 10,
        availableQuantity: 70,
        minStockLevel: 30,
        maxStockLevel: 120,
        lastMovementDate: null,
        warehouse: WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
        product: ProductEntity(
          id: 4,
          name: 'Доска обрезная 200x50x6000',
          productTemplateId: 1,
          unit: 'м³',
          producer: 'ООО "СтройМатериалы"',
        ),
      ),
    ];
  }

  /// Обработчик действий с остатками
  void _handleInventoryAction(String action, InventoryEntity inventory) {
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InventoryDetailsPage(inventory: inventory),
          ),
        ).then((_) => ref.read(inventoriesProvider.notifier).refresh());
        break;
      case 'movement':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockMovementFormPage(
              inventory: inventory,
              initialType: MovementType.outgoing,
            ),
          ),
        ).then((_) => ref.read(inventoriesProvider.notifier).refresh());
        break;
      case 'adjust':
        _showAdjustStockDialog(inventory);
        break;
      case 'restock':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockMovementFormPage(
              inventory: inventory,
              initialType: MovementType.incoming,
            ),
          ),
        ).then((_) => ref.read(inventoriesProvider.notifier).refresh());
        break;
      default:
        break;
    }
  }
}
