import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/presentation/providers/receipts_provider.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

/// Страница просмотра приемки
class ReceptionDetailsPage extends ConsumerWidget {
  final int receiptId;

  const ReceptionDetailsPage({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptByIdProvider(receiptId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Просмотр Приемка'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          receiptAsync.when(
            data: (receipt) => receipt.status != 'received'
                ? Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Принять товар'),
                            content: Text('Принять товар "${receipt.product?.name ?? 'Товар'}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
                              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text('Принять')),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await ref.read(receiptsProvider.notifier).receiveGoods(receipt.id);
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Принять товар'),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: SelectableText.rich(TextSpan(text: 'Ошибка: $error', style: const TextStyle(color: Colors.red)))),
        data: (receipt) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                context,
                title: 'Основная информация',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Склад назначения', receipt.warehouse?.name ?? '-'),
                    const SizedBox(height: 8),
                    _infoRow('Место отгрузки', receipt.transportInfo ?? '-'),
                    const SizedBox(height: 8),
                    _infoRow('Дата отправки', receipt.dispatchDate != null ? _formatDate(receipt.dispatchDate!) : '-'),
                    const SizedBox(height: 8),
                    _infoRow('Ожидаемая дата прибытия', receipt.expectedArrivalDate != null ? _formatDate(receipt.expectedArrivalDate!) : '-'),
                    const SizedBox(height: 8),
                    _infoRow('Фактическая дата прибытия', receipt.actualArrivalDate != null ? _formatDate(receipt.actualArrivalDate!) : '-'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _sectionCard(
                context,
                title: 'Информация о товаре',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.product?.name ?? 'Товар #${receipt.productId}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _infoRow('Количество', '${receipt.quantity.toStringAsFixed(0)} ${receipt.product?.unit ?? 'шт'}'),
                    const SizedBox(height: 8),
                    if (receipt.documentNumber != null) _infoRow('Документ', receipt.documentNumber!),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _sectionCard(
                context,
                title: 'Дополнительная информация',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.notes ?? '-', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 180, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}







