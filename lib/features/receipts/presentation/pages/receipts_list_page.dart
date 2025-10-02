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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    _searchController.dispose();
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


  void _applyFilters() {
    ref.invalidate(receiptsNotifierProvider(status: _selectedStatus, warehouseId: _selectedWarehouseId));
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск товаров в пути...',
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
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildReceiptsList(List<ReceiptEntity> receipts) {
    // Фильтруем по поисковому запросу
    final filteredReceipts = _searchQuery.isEmpty
        ? receipts
        : receipts.where((receipt) => 
            receipt.name.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    if (filteredReceipts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет товаров в пути'),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredReceipts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final receipt = filteredReceipts[index];
        return ReceiptCard(
          receipt: receipt,
          onTap: () => _openReceiptDetail(receipt),
          onReceive: () => _receiveReceipt(receipt),
        );
      },
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Поиск
          _buildSearchSection(),
          
          // Список товаров в пути
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: receiptsAsync.when(
                data: (receipts) => _buildReceiptsList(receipts),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onRefresh,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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