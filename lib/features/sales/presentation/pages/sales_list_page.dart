import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sale_form_page.dart';
import 'package:sum_warehouse/features/sales/presentation/providers/sales_providers.dart';
import 'package:sum_warehouse/features/sales/presentation/widgets/sale_card.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

/// Страница списка продаж
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedPaymentStatus;
  bool _showFilters = false;

  // Опции для статуса оплаты - только Оплачено и Отменено
  final List<Map<String, String>> _paymentStatusOptions = [
    {'value': '', 'label': 'Все статусы'},
    {'value': 'paid', 'label': 'Оплачено'},
    {'value': 'cancelled', 'label': 'Отменено'},
  ];

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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchSection(),
          if (_showFilters) _buildFiltersSection(),
          Expanded(child: _buildSalesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSale,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск продаж...',
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
              color: _showFilters ? AppColors.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showFilters ? AppColors.primary : const Color(0xFFE0E0E0),
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilters ? Colors.white : Colors.grey.shade600,
              ),
              tooltip: 'Фильтр',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
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
          // Первая строка: Статус оплаты
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentStatus,
                  decoration: InputDecoration(
                    labelText: 'Статус оплаты',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _paymentStatusOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentStatus = value;
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
                      initialDate: _dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateFrom = picked;
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
                      _dateFrom != null
                          ? '${_dateFrom!.day.toString().padLeft(2, '0')}.${_dateFrom!.month.toString().padLeft(2, '0')}.${_dateFrom!.year}'
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
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateTo = picked;
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
                      _dateTo != null
                          ? '${_dateTo!.day.toString().padLeft(2, '0')}.${_dateTo!.month.toString().padLeft(2, '0')}.${_dateTo!.year}'
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

  void _applyFilters() {
    // Формируем параметры дат (yyyy-MM-dd)
    String? dateFromStr = _dateFrom != null
        ? '${_dateFrom!.year.toString().padLeft(4, '0')}-${_dateFrom!.month.toString().padLeft(2, '0')}-${_dateFrom!.day.toString().padLeft(2, '0')}'
        : null;
    String? dateToStr = _dateTo != null
        ? '${_dateTo!.year.toString().padLeft(4, '0')}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
        : null;

    final currentFilters = ref.read(salesFiltersNotifierProvider);
    final newFilters = SaleFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseId: currentFilters.warehouseId,
      paymentStatus: _selectedPaymentStatus?.isEmpty == true ? null : _selectedPaymentStatus,
      dateFrom: dateFromStr,
      dateTo: dateToStr,
    );
    ref.read(salesFiltersNotifierProvider.notifier).updateFilters(newFilters);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _dateFrom = null;
      _dateTo = null;
      _selectedPaymentStatus = null;
    });
    ref.read(salesFiltersNotifierProvider.notifier).clearFilters();
  }

  Widget _buildSalesList() {
    final salesAsync = ref.watch(salesListProvider());

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesListProvider);
      },
      child: salesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_buildErrorState(error)],
        ),
        data: (salesResponse) {
          final sales = salesResponse.data;
          
          if (sales.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_buildEmptyState()],
            );
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            itemCount: sales.length,
            itemBuilder: (context, index) => SaleCard(
              sale: sales[index],
              onTap: () => _navigateToSaleDetail(sales[index]),
              onEdit: () => _navigateToEditSale(sales[index]),
              onCancel: () => _cancelSale(sales[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.point_of_sale,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Продажи не найдены',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первую продажу или измените фильтры поиска',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
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
            'Ошибка загрузки продаж',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(salesListProvider);
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateSale() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SaleFormPage(),
      ),
    ).then((result) {
      // Обновляем список только если форма была закрыта с результатом
      if (result == true || result == null) {
        ref.invalidate(salesListProvider);
      }
    });
  }

  void _navigateToSaleDetail(SaleModel sale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaleFormPage(
          sale: sale, 
          isViewMode: true,
        ),
      ),
    ).then((result) {
      // Обновляем список если продажа была отменена или изменена
      if (result == true) {
        ref.invalidate(salesListProvider);
      }
    });
  }

  void _navigateToEditSale(SaleModel sale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaleFormPage(sale: sale),
      ),
    ).then((result) {
      // Обновляем список только если форма была закрыта с результатом
      if (result == true || result == null) {
        ref.invalidate(salesListProvider);
      }
    });
  }

  Future<void> _cancelSale(SaleModel sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить продажу'),
        content: Text(
          'Вы уверены, что хотите отменить продажу №${sale.saleNumber ?? 'Без номера'}?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Отменить продажу',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Вызываем repository напрямую, без провайдера
        final repository = ref.read(salesRepositoryProvider);
        await repository.cancelSale(sale.id);
        
        // Инвалидируем провайдеры после успешной отмены
        ref.invalidate(salesListProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Продажа отменена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка отмены продажи: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
