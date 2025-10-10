import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sale_form_page.dart';
import 'package:sum_warehouse/features/sales/presentation/providers/sales_providers.dart';
import 'package:sum_warehouse/features/sales/presentation/widgets/sale_card.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Страница списка продаж
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _searchQuery;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchSection(),
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
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _performSearch();
        },
        decoration: InputDecoration(
          hintText: 'Поиск продаж...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
  }


  void _performSearch() {
    // Обновляем фильтры с поисковым запросом
    final currentFilters = ref.read(salesFiltersNotifierProvider);
    final newFilters = SaleFilters(
      search: _searchQuery?.isEmpty == true ? null : _searchQuery,
      warehouseId: currentFilters.warehouseId,
      paymentStatus: currentFilters.paymentStatus,
      dateFrom: currentFilters.dateFrom,
      dateTo: currentFilters.dateTo,
    );
    ref.read(salesFiltersNotifierProvider.notifier).updateFilters(newFilters);
  }

  void _clearSearch() {
    final currentFilters = ref.read(salesFiltersNotifierProvider);
    final newFilters = SaleFilters(
      search: null,
      warehouseId: currentFilters.warehouseId,
      paymentStatus: currentFilters.paymentStatus,
      dateFrom: currentFilters.dateFrom,
      dateTo: currentFilters.dateTo,
    );
    ref.read(salesFiltersNotifierProvider.notifier).updateFilters(newFilters);
  }

  Widget _buildSalesList() {
    final salesAsync = ref.watch(salesListProvider());

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesListProvider);
      },
      child: salesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => _buildErrorState(error),
        data: (salesResponse) {
          final sales = salesResponse.data;
          
          if (sales.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale,
                size: 64,
                color: Color(0xFFBDC3C7),
              ),
              SizedBox(height: 16),
              Text(
                'Продажи не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первую продажу или измените фильтры поиска',
                style: TextStyle(color: Color(0xFF6C757D)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(salesListProvider),
        ),
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
    );
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
        await ref.read(cancelSaleProvider.notifier).cancel(sale.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Продажа отменена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('🔴 Ошибка отмены продажи в UI: $e');
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