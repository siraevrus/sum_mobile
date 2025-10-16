import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/inventory_models.dart' as old_models;
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/inventory_stocks_provider.dart';
import '../../domain/entities/inventory_aggregation_entity.dart';

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
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              // Заголовок
              Text(
                producer.producer,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Информация о производителе
              _buildInfoRow('Позиций', '${producer.positionsCount}'),
              _buildInfoRow('Общий объем', '${producer.totalVolume.toStringAsFixed(3)} м³'),
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
              // Заголовок
              Text(
                warehouse.warehouse,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Информация о складе
              _buildInfoRow('Компания', warehouse.company),
              _buildInfoRow('Адрес', warehouse.address),
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
              // Заголовок
              Text(
                company.company,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Информация о компании
              _buildInfoRow('Складов', '${company.warehousesCount}'),
              _buildInfoRow('Позиций', '${company.positionsCount}'),
              _buildInfoRow('Общий объем', '${company.totalVolume.toStringAsFixed(3)} м³'),
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
          title: 'Остатки: ${producer.producer}',
          filterType: _FilterType.producer,
          filterId: producer.producerId,
        ),
      ),
    );
  }

  /// Показать остатки склада
  void _showWarehouseStocks(InventoryWarehouseModel warehouse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _InventoryStocksListPage(
          title: 'Остатки: ${warehouse.warehouse}',
          filterType: _FilterType.warehouse,
          filterId: warehouse.warehouseId,
        ),
      ),
    );
  }

  /// Показать остатки компании
  void _showCompanyStocks(InventoryCompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _InventoryStocksListPage(
          title: 'Остатки: ${company.company}',
          filterType: _FilterType.company,
          filterId: company.companyId,
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
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Обновляем текущий активный таб
              ref.invalidate(inventoryProducersProvider);
              ref.invalidate(inventoryWarehousesProvider);
              ref.invalidate(inventoryCompaniesProvider);
            },
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
  Widget build(BuildContext context) {
    // Используем новые провайдеры деталей в зависимости от типа фильтра
    final AsyncValue<PaginatedStockDetails> detailsAsync = switch (widget.filterType) {
      _FilterType.producer => ref.watch(producerDetailsProvider(widget.filterId)),
      _FilterType.warehouse => ref.watch(warehouseDetailsProvider(widget.filterId)),
      _FilterType.company => ref.watch(companyDetailsProvider(widget.filterId)),
    };
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: detailsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => _buildErrorState('Ошибка загрузки данных: $error'),
        data: (details) {
          if (details.data.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(producerDetailsProvider);
              ref.invalidate(warehouseDetailsProvider);
              ref.invalidate(companyDetailsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: details.data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildStockDetailCard(details.data[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockDetailCard(InventoryStockDetail stock) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Клик на карточку детального остатка
        },
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
              _buildInfoRow('Склад', stock.warehouse),
              _buildInfoRow('Производитель', stock.producer ?? 'Не указан'),
              _buildInfoRow('Количество', '${stock.quantity.toStringAsFixed(0)} шт.'),
              _buildInfoRow('Доступно', '${stock.availableQuantity.toStringAsFixed(0)} шт.'),
              _buildInfoRow('Продано', '${stock.soldQuantity.toStringAsFixed(0)} шт.'),
              _buildInfoRow('Объем', '${stock.totalVolume.toStringAsFixed(3)} м³'),
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Обновляем провайдеры
              ref.invalidate(producerDetailsProvider);
              ref.invalidate(warehouseDetailsProvider);
              ref.invalidate(companyDetailsProvider);
            },
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

  IconData _getCorrectionStatusIcon(String status) {
    switch (status) {
      case 'revised':
        return Icons.warning; // Предупреждение для "Требует корректировки"
      case 'correction':
        return Icons.edit_note; // Заметка для "Учтена корректировка"
      default:
        return Icons.info;
    }
  }
}
