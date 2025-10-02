import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipts_provider.dart';
import '../../domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';

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
            fontSize: 14,
            color: Colors.black,
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
  List<TemplateAttributeModel> _templateAttributes = [];
  bool _attributesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTemplateAttributes();
  }

  /// Загрузка атрибутов шаблона товара
  Future<void> _loadTemplateAttributes() async {
    try {
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final attributes = await dataSource.getTemplateAttributes(widget.receipt.productTemplateId);
      
      if (mounted) {
        setState(() {
          _templateAttributes = attributes;
          _attributesLoaded = true;
        });
      }
    } catch (e) {
      print('Ошибка загрузки атрибутов шаблона: $e');
      if (mounted) {
        setState(() {
          _attributesLoaded = true;
        });
      }
    }
  }

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
            // Блок Основная информация
            const Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            _buildViewField('Наименование', widget.receipt.name),
            if (widget.receipt.shippingLocation != null && widget.receipt.shippingLocation!.isNotEmpty)
              _buildViewField('Место отгрузки', widget.receipt.shippingLocation!),
            if (widget.receipt.shippingDate != null)
              _buildViewField('Дата отгрузки', _formatDate(widget.receipt.shippingDate!)),
            _buildViewField('Склад назначения', 'Склад ID: ${widget.receipt.warehouseId}'),
            if (widget.receipt.expectedArrivalDate != null)
              _buildViewField('Ожидаемая дата', _formatDate(widget.receipt.expectedArrivalDate!)),
            if (widget.receipt.transportNumber != null && widget.receipt.transportNumber!.isNotEmpty)
              _buildViewField('Номер транспорта', widget.receipt.transportNumber!),
            _buildViewField('Статус', _getStatusText(widget.receipt.status)),
            
            const SizedBox(height: 24),
            
            // Блок Информация о товаре
            const Text(
              'Информация о товаре',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.receipt.producerId != null)
              _buildViewField('Производитель', 'Производитель ID: ${widget.receipt.producerId}'),
            _buildViewField('Количество', '${widget.receipt.quantity} шт.'),
            if (widget.receipt.calculatedVolume != null)
              _buildViewField('Объем', '${widget.receipt.calculatedVolume!.toStringAsFixed(2)} м³'),
              
            const SizedBox(height: 24),
            
            // Блок Характеристики
            const Text(
              'Характеристики',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            if (!_attributesLoaded)
              const CircularProgressIndicator()
            else if (widget.receipt.attributes.isNotEmpty)
              _buildAttributesTable(widget.receipt.attributes)
            else
              const Text('Нет доступных характеристик', style: TextStyle(color: Color(0xFF6C757D))),
            
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFBBBBBB),
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
  
  /// Преобразует статус в текст на русском языке
  String _getStatusText(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.inTransit:
        return 'В пути';
      case ReceiptStatus.forReceipt:
        return 'К приемке';
      case ReceiptStatus.inStock:
        return 'На складе';
      default:
        return 'Неизвестный статус';
    }
  }
  
  /// Отображает таблицу атрибутов
  Widget _buildAttributesTable(Map<String, dynamic> attributes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDEE2E6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.entries.map((entry) {
          // Находим соответствующий атрибут по переменной
          final attribute = _templateAttributes.firstWhere(
            (attr) => attr.variable == entry.key,
            orElse: () => TemplateAttributeModel(
              id: 0,
              productTemplateId: 0,
              name: entry.key, // Если не найден, используем переменную
              variable: entry.key,
              type: 'text',
              isRequired: false,
            ),
          );
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFDEE2E6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    attribute.name, // Используем имя атрибута вместо переменной
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value?.toString() ?? 'Не указано',
                    style: const TextStyle(
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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
