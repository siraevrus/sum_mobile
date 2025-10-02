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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobileLayout();
              } else {
                return _buildDesktopLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '№${sale.saleNumber ?? 'Без номера'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Товар: ${sale.product?.name ?? 'ID ${sale.productId}'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  'Кол-во: ${sale.quantity.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${sale.totalPrice.toStringAsFixed(2)} ${sale.currency}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Дата: ${_formatDate(sale.saleDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildStatusChip(sale.paymentStatus),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              '№${sale.saleNumber ?? 'Без номера'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Товар: ${sale.product?.name ?? 'ID ${sale.productId}'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Кол-во: ${sale.quantity.toStringAsFixed(2)} • ${sale.totalPrice.toStringAsFixed(2)} ${sale.currency}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(sale.saleDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: _buildStatusChip(sale.paymentStatus),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => _buildMenuItems(),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final displayName = _getStatusDisplayName(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
