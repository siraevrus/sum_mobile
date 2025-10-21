import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sum_warehouse/shared/models/dashboard_stats.dart';

/// Таблица последних продаж
class LatestSalesTable extends StatelessWidget {
  final List<LatestSale> latestSales;
  
  const LatestSalesTable({
    super.key,
    required this.latestSales,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Убираем отступы, они будут управляться родителем
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Последние продажи',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (latestSales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Нет данных о продажах',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade50,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Название',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Количество',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Всего',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Дата',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: latestSales.map((sale) => DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            sale.productName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          sale.quantity.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(sale.totalAmount, sale.currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat('dd.MM.yyyy').format(sale.saleDate),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      customPattern: '0.00 \$',
    );
    return formatter.format(amount);
  }
}

/// Мобильная версия таблицы продаж (карточки)
class MobileLatestSalesCard extends StatelessWidget {
  final List<LatestSale> latestSales;
  
  const MobileLatestSalesCard({
    super.key,
    required this.latestSales,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Убираем отступы, они будут управляться родителем
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Последние продажи',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (latestSales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Нет данных о продажах',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: latestSales.map((sale) => _buildSaleCard(sale)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(LatestSale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sale.productName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Колонка 1: Количество
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Количество',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      sale.quantity.toInt().toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Колонка 2: Дата
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Дата',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy').format(sale.saleDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Колонка 3: Сумма
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Сумма',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatCurrency(sale.totalAmount, sale.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      customPattern: '0.00 \$',
    );
    return formatter.format(amount);
  }
}