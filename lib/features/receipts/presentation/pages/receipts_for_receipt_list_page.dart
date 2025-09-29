import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipts_provider.dart';
import '../../domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/receipts/data/datasources/receipts_remote_datasource.dart';

/// Страница приемки товаров (статус for_receipt)
class ReceiptsForReceiptListPage extends ConsumerStatefulWidget {
  const ReceiptsForReceiptListPage({super.key});

  @override
  ConsumerState<ReceiptsForReceiptListPage> createState() => _ReceiptsForReceiptListPageState();
}

class _ReceiptsForReceiptListPageState extends ConsumerState<ReceiptsForReceiptListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
      ref.read(receiptsNotifierProvider(status: 'for_receipt', warehouseId: _selectedWarehouseId).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(receiptsNotifierProvider(status: 'for_receipt', warehouseId: _selectedWarehouseId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsNotifierProvider(status: 'for_receipt', warehouseId: _selectedWarehouseId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Поиск
          _buildSearchSection(),
          
          // Список товаров для приемки
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

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск товаров для приемки...',
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
            Text('Нет товаров для приемки'),
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
        return _buildReceiptCard(receipt);
      },
    );
  }

  Widget _buildReceiptCard(ReceiptEntity receipt) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openReceiptDetail(receipt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок товара
              Row(
                children: [
                  Expanded(
                    child: Text(
                      receipt.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'К приемке',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Основная информация
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Количество', '${receipt.quantity} шт.'),
                  ),
                  if (receipt.calculatedVolume != null)
                    Expanded(
                      child: _buildInfoItem('Объем', '${receipt.calculatedVolume!.toStringAsFixed(2)} м³'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C757D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _openReceiptDetail(ReceiptEntity receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptsForReceiptDetailPage(receipt: receipt),
      ),
    ).then((_) => _onRefresh());
  }
}

/// Детальная страница товара для приемки (только просмотр)
class ReceiptsForReceiptDetailPage extends ConsumerStatefulWidget {
  final ReceiptEntity receipt;
  
  const ReceiptsForReceiptDetailPage({
    super.key,
    required this.receipt,
  });

  @override
  ConsumerState<ReceiptsForReceiptDetailPage> createState() => _ReceiptsForReceiptDetailPageState();
}

class _ReceiptsForReceiptDetailPageState extends ConsumerState<ReceiptsForReceiptDetailPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приемка товара'),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация в формате "Наименование: значение"
            _buildViewField('Наименование', widget.receipt.name),
            _buildViewField('Количество', '${widget.receipt.quantity} шт.'),
            _buildViewField('ID шаблона товара', widget.receipt.productTemplateId.toString()),
            _buildViewField('ID склада', widget.receipt.warehouseId.toString()),
            if (widget.receipt.producerId != null)
              _buildViewField('ID производителя', widget.receipt.producerId.toString()),
            if (widget.receipt.calculatedVolume != null)
              _buildViewField('Рассчитанный объем', '${widget.receipt.calculatedVolume!.toStringAsFixed(2)} м³'),
            if (widget.receipt.transportNumber != null && widget.receipt.transportNumber!.isNotEmpty)
              _buildViewField('Номер транспорта', widget.receipt.transportNumber!),
            if (widget.receipt.shippingLocation != null && widget.receipt.shippingLocation!.isNotEmpty)
              _buildViewField('Место отправки', widget.receipt.shippingLocation!),
            if (widget.receipt.shippingDate != null)
              _buildViewField('Дата отправки', _formatDate(widget.receipt.shippingDate!)),
            if (widget.receipt.expectedArrivalDate != null)
              _buildViewField('Ожидаемая дата прибытия', _formatDate(widget.receipt.expectedArrivalDate!)),
            
            const SizedBox(height: 32),
            
            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showCorrectionDialog,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Уточнение'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _receiveProduct,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Принимаем...' : 'Принять товар'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF6C757D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Показать диалог уточнения
  void _showCorrectionDialog() {
    final TextEditingController correctionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Уточнение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавьте уточнение к товару:'),
            const SizedBox(height: 16),
            TextField(
              controller: correctionController,
              decoration: const InputDecoration(
                hintText: 'Введите текст уточнения (10-1000 символов)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final correction = correctionController.text.trim();
              if (correction.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Уточнение должно содержать минимум 10 символов'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _sendCorrection(correction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39C12),
              foregroundColor: Colors.white,
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  /// Отправить уточнение
  Future<void> _sendCorrection(String correction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = ref.read(receiptsRemoteDataSourceProvider);
      await dataSource.addCorrection(widget.receipt.id, correction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Уточнение добавлено и товар принят'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Возврат к списку
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении уточнения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Принять товар
  Future<void> _receiveProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = ref.read(receiptsRemoteDataSourceProvider);
      await dataSource.receiveProduct(widget.receipt.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар принят'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Возврат к списку
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при приемке товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
