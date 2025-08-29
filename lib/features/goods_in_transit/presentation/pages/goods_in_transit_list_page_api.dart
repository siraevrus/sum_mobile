import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/goods_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/goods_in_transit/presentation/pages/product_in_transit_form_page.dart';

/// Экран списка товаров в пути (API версия)
class GoodsInTransitListPageApi extends ConsumerStatefulWidget {
  const GoodsInTransitListPageApi({super.key});

  @override
  ConsumerState<GoodsInTransitListPageApi> createState() => _GoodsInTransitListPageApiState();
}

class _GoodsInTransitListPageApiState extends ConsumerState<GoodsInTransitListPageApi> {
  final _searchController = TextEditingController();
  String? _filterStatus;
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goodsInTransitAsync = ref.watch(productsInTransitProvider);

    return Scaffold(
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Список товаров в пути
          Expanded(
            child: goodsInTransitAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    SelectableText.rich(
                      TextSpan(
                        text: 'Ошибка загрузки товаров в пути:\n',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        children: [
                          TextSpan(
                            text: error.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(productsInTransitProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              data: (receipts) {
                final filteredReceipts = _searchQuery.isEmpty
                  ? receipts
                  : receipts.where((r) => (r.product?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                if (filteredReceipts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нет товаров в пути',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Товары появятся здесь после отправки',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productsInTransitProvider.notifier).refresh();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredReceipts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final receipt = filteredReceipts[index];
                      return _buildReceiptCard(receipt);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProductInTransit,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить товар в пути',
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по товару, номеру документа...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
  
  Widget _buildStatusSummary(List<ReceiptEntity> receipts) {
    final inTransit = receipts.where((r) => r.status == 'in_transit').length;
    final arrived = receipts.where((r) => r.status == 'arrived').length;
    final received = receipts.where((r) => r.status == 'received').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'В пути',
              inTransit.toString(),
              AppColors.info,
              Icons.local_shipping,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Прибыли',
              arrived.toString(),
              AppColors.warning,
              Icons.place,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Принято',
              received.toString(),
              AppColors.success,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReceiptCard(ReceiptEntity receipt) {
    return GestureDetector(
      onTap: () => _viewReceiptDetails(receipt),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(0, 2),
    blurRadius: 6,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    offset: const Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  ),
],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Заголовок с продуктом и статусом
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.product?.name ?? 'Товар #${receipt.productId}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (receipt.documentNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Документ: ${receipt.documentNumber}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Статус
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getReceiptStatusColor(receipt.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusDisplayName(receipt.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getReceiptStatusColor(receipt.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Меню действий
                      PopupMenuButton<String>(
                        onSelected: (action) => _handleReceiptAction(action, receipt),
                        itemBuilder: (context) => [
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
                          if (receipt.status == 'arrived')
                            const PopupMenuItem(
                              value: 'receive',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Принять товар', style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Склад и количество
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.warehouse, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            receipt.warehouse?.name ?? 'Склад #${receipt.warehouseId}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Количество
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${receipt.quantity.toStringAsFixed(0)} ${receipt.product?.unit ?? 'шт'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Даты и транспорт
              if (receipt.dispatchDate != null || receipt.expectedArrivalDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (receipt.dispatchDate != null) ...[
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Отправлено: ${_formatDate(receipt.dispatchDate!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (receipt.expectedArrivalDate != null) ...[
                      Icon(Icons.event, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Ожидается: ${_formatDate(receipt.expectedArrivalDate!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Транспорт и водитель (если есть)
              if (receipt.transportInfo != null || receipt.driverInfo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (receipt.transportInfo != null) ...[
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              receipt.transportInfo!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (receipt.driverInfo != null) ...[
                        if (receipt.transportInfo != null) const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              receipt.driverInfo!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
  
  Color _getReceiptStatusColor(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.info;
      case 'arrived':
        return AppColors.warning;
      case 'received':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'in_transit':
        return 'В пути';
      case 'arrived':
        return 'Прибыл';
      case 'received':
        return 'Принят';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  void _viewReceiptDetails(ReceiptEntity receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductInTransitFormPage(
          productId: receipt.id,
          isEditing: true,
        ),
      ),
    ).then((_) {
      // Обновляем список после возврата из формы
      ref.read(productsInTransitProvider.notifier).refresh();
    });
  }

  void _createNewProductInTransit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductInTransitFormPage(
          isEditing: false,
        ),
      ),
    ).then((_) {
      // Обновляем список после создания
      ref.read(productsInTransitProvider.notifier).refresh();
    });
  }
  
  void _handleReceiptAction(String action, ReceiptEntity receipt) {
    switch (action) {
      case 'view':
        _viewReceiptDetails(receipt);
        break;
      case 'receive':
        _receiveGoods(receipt);
        break;
    }
  }
  
  Future<void> _receiveGoods(ReceiptEntity receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Принять товар'),
        content: Text('Принять товар "${receipt.product?.name ?? 'Товар #${receipt.productId}'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Принять', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productsInTransitProvider.notifier).receiveProduct(receipt.id);
        // Автоматически обновляем список
        await ref.read(productsInTransitProvider.notifier).refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${receipt.product?.name ?? 'Товар #${receipt.productId}'}" успешно принят'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при принятии товара: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }


}
