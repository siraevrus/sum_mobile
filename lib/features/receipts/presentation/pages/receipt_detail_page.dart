import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/receipts_provider.dart';
import '../../domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';

class ReceiptDetailPage extends ConsumerStatefulWidget {
  final int receiptId;

  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
  });

  @override
  ConsumerState<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends ConsumerState<ReceiptDetailPage> {
  List<TemplateAttributeModel> _templateAttributes = [];
  bool _attributesLoaded = false;
  
  /// Загрузка атрибутов шаблона товара
  Future<void> _loadTemplateAttributes(int productTemplateId) async {
    if (_attributesLoaded) return; // Загружаем только один раз
    
    try {
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final attributes = await dataSource.getTemplateAttributes(productTemplateId);
      
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
    final receiptAsync = ref.watch(receiptDetailProvider(widget.receiptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали приемки'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              if (receiptAsync.value?.status == ReceiptStatus.forReceipt)
                const PopupMenuItem(
                  value: 'receive',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Принять товар'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Редактировать'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
                onPressed: () => ref.invalidate(receiptDetailProvider(widget.receiptId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (receipt) {
          // Загружаем атрибуты шаблона при получении данных о приемке
          _loadTemplateAttributes(receipt.productTemplateId);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, receipt),
                const SizedBox(height: 24),
                _buildMainInfo(context, receipt),
                const SizedBox(height: 24),
                _buildShippingInfo(context, receipt),
                const SizedBox(height: 24),
                _buildAttributes(context, receipt),
                if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNotes(context, receipt),
                ],
                const SizedBox(height: 24),
                _buildSystemInfo(context, receipt),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(context, receipt.status),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Основная информация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Наименование',
              receipt.name,
              Icons.label_outlined,
            ),
            if (receipt.shippingLocation != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Место отгрузки',
                receipt.shippingLocation!,
                Icons.location_on_outlined,
              ),
            ],
            if (receipt.shippingDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Дата отгрузки',
                DateFormat('dd.MM.yyyy').format(receipt.shippingDate!),
                Icons.calendar_today_outlined,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Склад назначения',
              'Склад ID: ${receipt.warehouseId}',
              Icons.warehouse_outlined,
            ),
            if (receipt.expectedArrivalDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Ожидаемая дата',
                DateFormat('dd.MM.yyyy').format(receipt.expectedArrivalDate!),
                Icons.schedule_outlined,
              ),
            ],
            if (receipt.transportNumber != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Номер транспорта',
                receipt.transportNumber!,
                Icons.local_shipping_outlined,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Статус',
              _getStatusText(receipt.status),
              Icons.info_outline,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildShippingInfo(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о товаре',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (receipt.producerId != null) ...[
              _buildInfoRow(
                context,
                'Производитель',
                'Производитель ID: ${receipt.producerId}',
                Icons.business_outlined,
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              context,
              'Количество',
              '${receipt.quantity} шт.',
              Icons.inventory_2_outlined,
            ),
            if (receipt.calculatedVolume != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Объем',
                '${receipt.calculatedVolume!.toStringAsFixed(2)} м³',
                Icons.straighten_outlined,
              ),
            ],
            if (receipt.documentPath != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Документ',
                receipt.documentPath!,
                Icons.description_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заметки',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                receipt.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributes(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Характеристики',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!_attributesLoaded)
              const CircularProgressIndicator()
            else if (receipt.attributes.isEmpty)
              const Text('Нет доступных характеристик')
            else
              _buildAttributesTable(context, receipt.attributes),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttributesTable(BuildContext context, Map<String, dynamic> attributes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
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

  Widget _buildSystemInfo(BuildContext context, ReceiptEntity receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Системная информация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'ID',
              receipt.id.toString(),
              Icons.tag,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Создано',
              DateFormat('dd.MM.yyyy HH:mm').format(receipt.createdAt),
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Обновлено',
              DateFormat('dd.MM.yyyy HH:mm').format(receipt.updatedAt),
              Icons.update,
            ),
            if (receipt.createdBy != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Создал пользователь',
                receipt.createdBy.toString(),
                Icons.person,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ReceiptStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case ReceiptStatus.inTransit:
        chipColor = Colors.orange;
        statusText = 'В пути';
        break;
      case ReceiptStatus.forReceipt:
        chipColor = Colors.blue;
        statusText = 'К приемке';
        break;
      case ReceiptStatus.inStock:
        chipColor = Colors.green;
        statusText = 'На складе';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
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

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'receive':
        _showReceiveDialog(context, ref);
        break;
      case 'edit':
        Navigator.pushNamed(context, '/receipts/edit', arguments: receiptId);
        break;
    }
  }

  Future<void> _showReceiveDialog(BuildContext context, WidgetRef ref) async {
    final receipt = ref.read(receiptDetailProvider(receiptId)).value;
    if (receipt == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReceiveDialog(receipt: receipt),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(receiptsNotifierProvider(status: null, warehouseId: null).notifier).receiveProducts(
              receiptId: receiptId,
              actualQuantity: result['quantity'] as int?,
              notes: result['notes'] as String?,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Товар успешно принят'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the detail view
          ref.invalidate(receiptDetailProvider(receiptId));
        }
      } catch (e) {
        if (context.mounted) {
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