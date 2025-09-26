import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipts_provider.dart';
import '../widgets/receipt_card.dart';
import '../../domain/entities/receipt_entity.dart';
import 'receipt_detail_page.dart';

class ReceiptsListPage extends ConsumerStatefulWidget {
  const ReceiptsListPage({super.key});

  @override
  ConsumerState<ReceiptsListPage> createState() => _ReceiptsListPageState();
}

class _ReceiptsListPageState extends ConsumerState<ReceiptsListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus = 'in_transit'; // Default to in_transit for "Товары в пути"
  int? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more when reaching the bottom
      ref.read(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId).notifier).refresh();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Все')),
                DropdownMenuItem(value: 'in_transit', child: Text('В пути')),
                DropdownMenuItem(value: 'for_receipt', child: Text('К приемке')),
                DropdownMenuItem(value: 'in_stock', child: Text('На складе')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Add warehouse filter here if needed
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    ref.invalidate(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId));
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(
      receiptsNotifierProvider(
        status: _selectedStatus,
        warehouseId: _selectedWarehouseId,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары в пути'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔵 Manual refresh triggered');
              ref.invalidate(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create receipt page when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Создание приемки будет реализовано позже'),
                ),
              );
            },
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки данных',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onRefresh,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        data: (receipts) {
          if (receipts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет товаров в пути',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Товары в пути будут отображаться здесь',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReceiptCard(
                    receipt: receipt,
                    onTap: () => _openReceiptDetail(receipt),
                    onReceive: () => _receiveReceipt(receipt),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openReceiptDetail(ReceiptEntity receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptDetailPage(receiptId: receipt.id),
      ),
    );
  }

  Future<void> _receiveReceipt(ReceiptEntity receipt) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReceiveDialog(receipt: receipt),
    );

    if (result != null && mounted) {
      try {
        await ref.read(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId).notifier).receiveProducts(
              receiptId: receipt.id,
              actualQuantity: result['quantity'] as int?,
              notes: result['notes'] as String?,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Товар успешно принят'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ReceiveDialog extends StatefulWidget {
  final ReceiptEntity receipt;

  const _ReceiveDialog({required this.receipt});

  @override
  State<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<_ReceiveDialog> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.receipt.quantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Принять товар'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Фактическое количество',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Заметки (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final quantity = int.tryParse(_quantityController.text);
            Navigator.pop(context, {
              'quantity': quantity,
              'notes': _notesController.text.isEmpty 
                  ? null 
                  : _notesController.text,
            });
          },
          child: const Text('Принять'),
        ),
      ],
    );
  }
}