import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sale_form_page.dart';
import 'package:sum_warehouse/shared/models/sale_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Страница списка продаж
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  String? _searchQuery;
  String? _paymentStatusFilter;
  String? _deliveryStatusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildSalesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SaleFormPage(),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.point_of_sale,
            color: Color(0xFF2ECC71),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Продажи',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SaleFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Создать'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPaymentStatusFilter()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDeliveryStatusFilter()),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(child: _buildPaymentStatusFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildDeliveryStatusFilter()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Поиск продаж...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF007BFF)),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
    );
  }

  Widget _buildPaymentStatusFilter() {
    return DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
      value: _paymentStatusFilter,
      onChanged: (value) => setState(() => _paymentStatusFilter = value),
      decoration: InputDecoration(
        labelText: 'Статус оплаты',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Все')),
        DropdownMenuItem(value: 'paid', child: Text('Оплачено')),
        DropdownMenuItem(value: 'pending', child: Text('Ожидает оплаты')),
        DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
      ],
    );
  }

  Widget _buildDeliveryStatusFilter() {
    return DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
      value: _deliveryStatusFilter,
      onChanged: (value) => setState(() => _deliveryStatusFilter = value),
      decoration: InputDecoration(
        labelText: 'Статус доставки',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Все')),
        DropdownMenuItem(value: 'processing', child: Text('Обрабатывается')),
        DropdownMenuItem(value: 'shipped', child: Text('Отправлено')),
        DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
        DropdownMenuItem(value: 'returned', child: Text('Возвращено')),
      ],
    );
  }

  Widget _buildSalesList() {
    final dataSource = ref.watch(salesRemoteDataSourceProvider);

    return FutureBuilder(
      future: dataSource.getSales(
        search: _searchQuery,
        paymentStatus: _paymentStatusFilter,
        deliveryStatus: _deliveryStatusFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final sales = snapshot.data?.data ?? [];
        
        if (sales.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          itemBuilder: (context, index) => _buildSaleCard(sales[index]),
        );
      },
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _handleSaleAction('edit', sale),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobileSaleCard(sale);
              } else {
                return _buildDesktopSaleCard(sale);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSaleCard(SaleModel sale) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '№${sale.saleNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
                          ),
              const SizedBox(height: 8),
            Text('Товар: ${sale.product?.name ?? 'ID ${sale.productId ?? 'Не указан'}'}'),
            Text('Количество: ${sale.quantity ?? 0}'),
            Text('Сумма: ${sale.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
            if (sale.customerName != null) Text('Клиент: ${sale.customerName}'),
            const SizedBox(height: 8),
            _buildStatusChips(sale),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: PopupMenuButton<String>(
            onSelected: (action) => _handleSaleAction(action, sale),
            itemBuilder: (context) => [
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
        ),
      ],
    );
  }

  Widget _buildDesktopSaleCard(SaleModel sale) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '№${sale.saleNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text('Товар: ${sale.product?.name ?? 'ID ${sale.productId ?? 'Не указан'}'}'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Количество: ${sale.quantity ?? 0}'),
              Text('₽${sale.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sale.customerName != null)
                Text(sale.customerName!)
              else
                const Text('-'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildStatusChips(sale),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (action) => _handleSaleAction(action, sale),
          itemBuilder: (context) => [
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
    );
  }

  Widget _buildStatusChips(SaleModel sale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusChip(
          sale.paymentStatus ?? 'pending',
          _getPaymentStatusColor(sale.paymentStatus ?? 'pending'),
        ),
        const SizedBox(height: 4),
        _buildStatusChip(
          sale.deliveryStatus ?? 'pending',
          _getDeliveryStatusColor(sale.deliveryStatus ?? 'pending'),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleSaleAction(String action, SaleModel sale) {
    switch (action) {
      case 'view':
        // TODO: Просмотр деталей продажи
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SaleFormPage(sale: sale),
          ),
        ).then((_) => setState(() {}));
        break;
      case 'delete':
        // TODO: Удаление продажи
        break;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
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
    );
  }

  Widget _buildErrorState() {
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
          const Text(
            'Ошибка загрузки продаж',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF2ECC71);
      case 'pending':
        return const Color(0xFFF39C12);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF2ECC71);
      case 'shipped':
        return const Color(0xFF3498DB);
      case 'processing':
        return const Color(0xFFF39C12);
      case 'returned':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6C757D);
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'paid':
        return 'Оплачено';
      case 'pending':
        return 'Ожидает оплаты';
      case 'cancelled':
        return 'Отменено';
      case 'delivered':
        return 'Доставлено';
      case 'shipped':
        return 'Отправлено';
      case 'processing':
        return 'Обрабатывается';
      case 'returned':
        return 'Возвращено';
      default:
        return status;
    }
  }
}
