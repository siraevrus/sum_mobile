import 'package:flutter/material.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';

/// Full screen details for a stock item
class StockDetailsPage extends StatefulWidget {
  final StockModel stock;

  const StockDetailsPage({super.key, required this.stock});

  @override
  State<StockDetailsPage> createState() => _StockDetailsPageState();
}

class _StockDetailsPageState extends State<StockDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    return Scaffold(
      appBar: AppBar(
        title: Text(stock.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // No actions in AppBar - edit icon removed as requested
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Производитель', stock.producer ?? 'Не указан'),
              _buildInfoRow('Склад', stock.warehouse?.name ?? 'Неизвестен'),
              _buildInfoRow('Товаров', '${stock.itemsCount}'),
              _buildInfoRow('Доступное количество', '${stock.availableQuantity}'),
              if (stock.availableVolume != null)
                _buildInfoRow('Общий объем', '${stock.availableVolume!.toStringAsFixed(2)} м³'),
              if (stock.firstArrival != null)
                _buildInfoRow('Первое поступление', '${stock.firstArrival!.day}.${stock.firstArrival!.month}.${stock.firstArrival!.year}'),
              if (stock.lastArrival != null)
                _buildInfoRow('Последнее поступление', '${stock.lastArrival!.day}.${stock.lastArrival!.month}.${stock.lastArrival!.year}'),
            ],
          ),
        ),
      ),
    );
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




