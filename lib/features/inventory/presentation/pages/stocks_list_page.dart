import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';
import 'package:sum_warehouse/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/create_stock_form_page.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/stock_details_page.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Экран списка остатков (новая реализация в соответствии с API)
class StocksListPage extends ConsumerStatefulWidget {
  const StocksListPage({super.key});

  @override
  ConsumerState<StocksListPage> createState() => _StocksListPageState();
}

class _StocksListPageState extends ConsumerState<StocksListPage> {
  final _searchController = TextEditingController();
  String? _selectedProducer;
  int? _selectedWarehouseId;
  
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

  List<StockModel> get _filteredStocks {
    var filtered = _stocks;
    
    // Фильтр по поиску
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((stock) =>
        stock.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        (stock.producer?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Фильтр по производителю
    if (_selectedProducer != null) {
      filtered = filtered.where((stock) => stock.producer == _selectedProducer).toList();
    }
    // Фильтр по складу
    if (_selectedWarehouseId != null) {
      filtered = filtered.where((stock) => stock.warehouse?.id == _selectedWarehouseId).toList();
    }
    
    return filtered;
  }

  Set<String> get _availableProducers {
    return _stocks
        .where((stock) => stock.producer != null)
        .map((stock) => stock.producer!)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateStockFormPage(),
            ),
          ).then((created) {
            if (created == true) {
              _loadStocks();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStocks,
        child: Column(
          children: [
            // Поиск + кнопка фильтра
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    color: AppColors.primary,
                    onPressed: _showFilters,
                    tooltip: 'Фильтры',
                  ),
                ],
              ),
            ),
            // Фильтр по производителю
            if (_selectedProducer != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.surfaceVariant,
                child: Row(
                  children: [
                    const Text('Производитель: '),
                    Text(
                      _selectedProducer!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedProducer = null),
                      child: const Text('Очистить'),
                    ),
                  ],
                ),
              ),
            // Список остатков
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    final filteredStocks = _filteredStocks;
    
    if (filteredStocks.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStocks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildStockCard(filteredStocks[index]);
      },
    );
  }

  Widget _buildStockCard(StockModel stock) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showStockDetails(stock),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                 const Text(
                    'выа: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              Text(
                stock.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Производитель
              if (stock.producer != null)
              Row(
                children: [
                  const Text(
                    'Производитель: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${stock.producer!}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Количество и объем
              Row(
                children: [
                  const Text(
                    'Товаров: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${stock.itemsCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  const Text(
                    'Общий объем: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${stock.availableVolume?.toStringAsFixed(2) ?? "0"} м³',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Кнопка просмотра
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showStockDetails(stock),
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
                        'Просмотреть',
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

  Widget _buildErrorState() {
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
            _error ?? 'Неизвестная ошибка',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
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
            'Проверьте фильтры или создайте товар',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Фильтр по складу
            FutureBuilder(
              future: ref.read(warehousesRemoteDataSourceProvider).getWarehouses(),
              builder: (context, snapshot) {
                final warehouses = snapshot.hasData ? snapshot.data!.data : [];
                return DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                  value: _selectedWarehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Склад',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все')),
                    ...warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedWarehouseId = value);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Фильтр по производителю
            DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
              value: _selectedProducer,
              decoration: const InputDecoration(
                labelText: 'Производитель',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Все'),
                ),
                ..._availableProducers.map((producer) => DropdownMenuItem(
                  value: producer,
                  child: Text(producer),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProducer = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDetails(StockModel stock) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StockDetailsPage(stock: stock)),
    ).then((updated) {
      if (updated == true) {
        _loadStocks();
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
