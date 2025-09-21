import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/reception/presentation/providers/receipts_provider.dart';

/// Экран списка товаров в пути
class GoodsInTransitListPage extends ConsumerStatefulWidget {
  const GoodsInTransitListPage({super.key});

  @override
  ConsumerState<GoodsInTransitListPage> createState() => _GoodsInTransitListPageState();
}

class _GoodsInTransitListPageState extends ConsumerState<GoodsInTransitListPage> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createTransit,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Новое перемещение',
      ),
      
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Список товаров в пути
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(goodsInTransitProvider.notifier).refresh();
              },
              child: _buildGoodsInTransitList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
          // Поиск с задержкой
          Future.delayed(const Duration(milliseconds: 500), () {
            if (value == _searchController.text) {
              ref.read(goodsInTransitProvider.notifier).search(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildGoodsInTransitList() {
    final goodsInTransitAsync = ref.watch(goodsInTransitProvider);

    return goodsInTransitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки товаров в пути:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(goodsInTransitProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (receipts) {
        if (receipts.isEmpty) {
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
              ],
            ),
          );
        }

        // Список уже отсортирован в провайдере по дате создания
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: receipts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final receipt = receipts[index];
            return _buildTransitCard(receipt);
          },
        );
      },
    );
  }
  
  Widget _buildTransitCard(ReceiptEntity receipt) {
    return GestureDetector(
      onTap: () => _viewTransitDetails(receipt),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с информацией о товаре
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
                  
                  // Статус
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'В пути',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Меню действий
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleTransitAction(action, receipt),
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
                      const PopupMenuItem(
                        value: 'track',
                        child: Row(
                          children: [
                            Icon(Icons.timeline, size: 20),
                            SizedBox(width: 8),
                            Text('Отслеживание'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Информация о складе и количестве
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.warehouse, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            receipt.warehouse?.name ?? 'Склад #${receipt.warehouseId}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Даты
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
                    Icon(
                      Icons.event,
                      size: 14,
                      color: Colors.grey[600],
                    ),
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
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  void _createTransit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание перемещения - в разработке')),
    );
  }
  
  void _handleTransitAction(String action, ReceiptEntity receipt) {
    switch (action) {
      case 'view':
        _viewTransitDetails(receipt);
        break;
      case 'track':
        _showTrackingHistory(receipt);
        break;
    }
  }
  
  void _viewTransitDetails(ReceiptEntity receipt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр "${receipt.product?.name}"')),
    );
  }
  
  void _showTrackingHistory(ReceiptEntity receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('История отслеживания'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mock данные отслеживания
              _buildTrackingEvent('Товар отправлен со склада', _formatDate(receipt.createdAt)),
              _buildTrackingEvent('Товар в пути', 'Сегодня ${TimeOfDay.now().format(context)}'),
              if (receipt.expectedArrivalDate != null)
                _buildTrackingEvent('Ожидается прибытие', 'Ожидается ${_formatDate(receipt.expectedArrivalDate!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingEvent(String event, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
