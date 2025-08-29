import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/reception/presentation/providers/receipts_provider.dart';
import 'package:sum_warehouse/features/reception/presentation/pages/reception_details_page.dart';

/// Экран списка приемок
class ReceptionListPage extends ConsumerStatefulWidget {
  const ReceptionListPage({super.key});

  @override
  ConsumerState<ReceptionListPage> createState() => _ReceptionListPageState();
}

class _ReceptionListPageState extends ConsumerState<ReceptionListPage> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(receiptsProvider.notifier).refresh(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Обновить список',
      ),
      body: Column(
        children: [
          // Поиск и фильтры
          _buildSearchBar(),
          
          // Список приемок
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(receiptsProvider.notifier).refresh();
              },
              child: _buildReceptionsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск приемок...',
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
        onChanged: (value) {
          // Поиск с задержкой
          Future.delayed(const Duration(milliseconds: 500), () {
            if (value == _searchController.text) {
              ref.read(receiptsProvider.notifier).searchReceipts(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildReceptionsList() {
    final receiptsAsync = ref.watch(receiptsProvider);

    return receiptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки приемок:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(receiptsProvider.notifier).refresh(),
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
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет приемок',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: receipts.length,
          itemBuilder: (context, index) => _buildReceptionCard(receipts[index]),
        );
      },
    );
  }

  Widget _buildReceptionCard(ReceiptEntity receipt) {
    final status = _getReceiptStatus(receipt.status);
    final statusColor = _getStatusColor(receipt.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openReceiptDetails(receipt),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.documentNumber ?? 'Приемка #${receipt.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (receipt.product != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            receipt.product!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleReceptionAction(action, receipt),
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
                      if (receipt.status != 'received')
                        const PopupMenuItem(
                          value: 'receive',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Принять'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (receipt.warehouse != null) ...[
                Text(
                  'Склад: ${receipt.warehouse!.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
              ],

              Text(
                'Количество: ${receipt.quantity.toStringAsFixed(0)} ${receipt.product?.unit ?? 'шт'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              if (receipt.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  receipt.description!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(receipt.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

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
                            Icon(Icons.local_shipping, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              receipt.transportInfo!,
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
      ),
    );
  }

  void _handleReceptionAction(String action, ReceiptEntity receipt) async {
    switch (action) {
      case 'view':
        _openReceiptDetails(receipt);
        break;
      case 'receive':
        await _receiveGoods(receipt);
        break;
    }
  }

  void _openReceiptDetails(ReceiptEntity receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceptionDetailsPage(receiptId: receipt.id),
      ),
    ).then((_) => ref.read(receiptsProvider.notifier).refresh());
  }

  Future<void> _receiveGoods(ReceiptEntity receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Принять товар'),
        content: Text(
          'Подтвердить принятие товара "${receipt.product?.name}" в количестве ${receipt.quantity.toStringAsFixed(0)} ${receipt.product?.unit ?? 'шт'}?',
        ),
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
        await ref.read(receiptsProvider.notifier).receiveGoods(receipt.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${receipt.product?.name}" принят'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }



  void _createReception() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание новой приемки - в разработке')),
    );
  }

  String _getReceiptStatus(String status) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.warning;
      case 'arrived':
        return AppColors.info;
      case 'received':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}



