import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/inventory_stocks_provider.dart';

/// Экран остатков на складе с табуляцией
class InventoryTabsPage extends ConsumerStatefulWidget {
  const InventoryTabsPage({super.key});

  @override
  ConsumerState<InventoryTabsPage> createState() => _InventoryTabsPageState();
}

class _InventoryTabsPageState extends ConsumerState<InventoryTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // Загружаем остатки по умолчанию
    ref.read(inventoryStocksProvider.notifier).loadStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Табы
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Производитель'),
                Tab(text: 'Склад'),
                Tab(text: 'Компания'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Контент табов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProducerTab(),
                _buildWarehouseTab(),
                _buildCompanyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Таб "Производитель"
  Widget _buildProducerTab() {
    final producersAsync = ref.watch(inventoryProducersProvider);
    final stocksState = ref.watch(inventoryStocksProvider);
    
    return producersAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, stack) => _buildErrorState('Ошибка загрузки производителей: $error'),
      data: (producers) {
        if (producers.isEmpty) {
          return _buildEmptyState('Нет производителей');
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(inventoryProducersProvider.notifier).refresh();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: producers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final producer = producers[index];
              return _buildProducerCard(producer, stocksState);
            },
          ),
        );
      },
    );
  }

  /// Таб "Склад"
  Widget _buildWarehouseTab() {
    final warehousesAsync = ref.watch(inventoryWarehousesProvider);
    
    return warehousesAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, stack) => _buildErrorState('Ошибка загрузки складов: $error'),
      data: (warehouses) {
        if (warehouses.isEmpty) {
          return _buildEmptyState('Нет складов');
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(inventoryWarehousesProvider.notifier).refresh();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: warehouses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final warehouse = warehouses[index];
              return _buildWarehouseCard(warehouse);
            },
          ),
        );
      },
    );
  }

  /// Таб "Компания"
  Widget _buildCompanyTab() {
    final companiesAsync = ref.watch(inventoryCompaniesProvider);
    
    return companiesAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, stack) => _buildErrorState('Ошибка загрузки компаний: $error'),
      data: (companies) {
        if (companies.isEmpty) {
          return _buildEmptyState('Нет компаний');
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(inventoryCompaniesProvider.notifier).refresh();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: companies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final company = companies[index];
              return _buildCompanyCard(company);
            },
          ),
        );
      },
    );
  }

  /// Карточка производителя
  Widget _buildProducerCard(InventoryProducerModel producer, InventoryStocksState stocksState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProducerStocks(producer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producer.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (producer.region != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Регион: ${producer.region}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (producer.productsCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Товаров: ${producer.productsCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showProducerStocks(producer),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Показать остатки',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка склада
  Widget _buildWarehouseCard(InventoryWarehouseModel warehouse) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWarehouseStocks(warehouse),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                warehouse.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                warehouse.address,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (warehouse.company != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Компания: ${warehouse.company!.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showWarehouseStocks(warehouse),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Показать остатки',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка компании
  Widget _buildCompanyCard(InventoryCompanyModel company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCompanyStocks(company),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ИНН: ${company.inn}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                company.legalAddress,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (company.warehousesCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Складов: ${company.warehousesCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCompanyStocks(company),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Показать остатки',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показать остатки производителя
  void _showProducerStocks(InventoryProducerModel producer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _InventoryStocksListPage(
          title: 'Остатки: ${producer.name}',
          filterType: _FilterType.producer,
          filterId: producer.id,
        ),
      ),
    );
  }

  /// Показать остатки склада
  void _showWarehouseStocks(InventoryWarehouseModel warehouse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _InventoryStocksListPage(
          title: 'Остатки: ${warehouse.name}',
          filterType: _FilterType.warehouse,
          filterId: warehouse.id,
        ),
      ),
    );
  }

  /// Показать остатки компании
  void _showCompanyStocks(InventoryCompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _InventoryStocksListPage(
          title: 'Остатки: ${company.name}',
          filterType: _FilterType.company,
          filterId: company.id,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ошибка',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

enum _FilterType { producer, warehouse, company }

/// Страница со списком остатков с фильтрацией
class _InventoryStocksListPage extends ConsumerStatefulWidget {
  final String title;
  final _FilterType filterType;
  final int filterId;

  const _InventoryStocksListPage({
    required this.title,
    required this.filterType,
    required this.filterId,
  });

  @override
  ConsumerState<_InventoryStocksListPage> createState() => _InventoryStocksListPageState();
}

class _InventoryStocksListPageState extends ConsumerState<_InventoryStocksListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilteredStocks();
    });
  }

  void _loadFilteredStocks() {
    switch (widget.filterType) {
      case _FilterType.warehouse:
        // Серверная фильтрация по складу
        ref.read(inventoryStocksProvider.notifier).loadStocks(
          warehouseId: widget.filterId,
        );
        break;
      case _FilterType.producer:
      case _FilterType.company:
        // Для производителя и компании загружаем все остатки
        // Фильтрация будет на клиенте
        ref.read(inventoryStocksProvider.notifier).loadStocks();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stocksState = ref.watch(inventoryStocksProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildStocksContent(stocksState),
    );
  }

  Widget _buildStocksContent(InventoryStocksState state) {
    switch (state) {
      case InventoryStocksLoading():
        return const LoadingWidget();
      case InventoryStocksError():
        return _buildErrorState(state.message);
      case InventoryStocksLoaded():
        List<InventoryStockModel> filteredStocks = state.stocks;
        
        // Клиентская фильтрация для производителя и компании
        if (widget.filterType == _FilterType.producer) {
          filteredStocks = state.stocks.where((stock) => stock.producerId == widget.filterId).toList();
        } else if (widget.filterType == _FilterType.company) {
          // Фильтрация по компании через склады
          filteredStocks = state.stocks.where((stock) => 
            stock.warehouse?.companyId == widget.filterId
          ).toList();
        }
        
        if (filteredStocks.isEmpty) {
          return _buildEmptyState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            _loadFilteredStocks();
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

  Widget _buildStockCard(InventoryStockModel stock) {
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
            
            if (stock.warehouse != null) ...[
              _buildInfoRow('Склад', stock.warehouse!.name),
            ],
            
            if (stock.producer != null) ...[
              _buildInfoRow('Производитель', stock.producer!.name),
            ],
            
            _buildInfoRow('Количество', stock.totalQuantity),
            _buildInfoRow('Объем', '${stock.totalVolume} м³'),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stock.status == 'in_stock' ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stock.status == 'in_stock' ? 'В наличии' : stock.status,
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Ошибка',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFilteredStocks,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Нет остатков',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
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
