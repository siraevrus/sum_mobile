import 'package:flutter/material.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Виджет карточки продажи
class SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const SaleCard({
    super.key,
    required this.sale,
    this.onTap,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с меню
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '№${sale.saleNumber ?? 'Без номера'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => _buildMenuItems(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Информация о продаже
              _buildInfoRow('Товар', sale.product?.name ?? 'ID ${sale.productId}'),
              _buildInfoRow('Количество', sale.quantity.toInt().toString()),
              _buildInfoRow('Цена за единицу', '${sale.unitPrice.toStringAsFixed(2)} ${sale.currency}'),
              _buildInfoRow('Общая сумма', '${sale.totalPrice.toStringAsFixed(2)} ${sale.currency}'),
              _buildInfoRow('Склад', sale.warehouse?.name ?? 'ID ${sale.warehouseId}'),
              _buildInfoRow('Дата продажи', _formatDate(sale.saleDate)),
              
              // Тег статуса оплаты
              const SizedBox(height: 8),
              _buildStatusChip(sale.paymentStatus),
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

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final displayName = _getStatusDisplayName(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      case 'partially_paid':
        return Icons.payments;
      default:
        return Icons.info;
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[
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
    ];

    // Добавляем опцию отмены только для неотмененных продаж
    if (sale.paymentStatus != 'cancelled') {
      items.add(
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('Отменить', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view':
        onTap?.call();
        break;
      case 'cancel':
        onCancel?.call();
        break;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'partially_paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'paid':
        return 'Оплачено';
      case 'cancelled':
        return 'Отменено';
      case 'pending':
        return 'Ожидание';
      case 'partially_paid':
        return 'Частично оплачено';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Дата не указана';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
