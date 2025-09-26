import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/providers/products_in_transit_provider.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';

/// Страница просмотра товара в пути
class ProductsInTransitDetailsPage extends ConsumerStatefulWidget {
  final int productInTransitId;

  const ProductsInTransitDetailsPage({super.key, required this.productInTransitId});

  @override
  ConsumerState<ProductsInTransitDetailsPage> createState() => _ProductsInTransitDetailsPageState();
}

class _ProductsInTransitDetailsPageState extends ConsumerState<ProductsInTransitDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _actualQuantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _actualQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productInTransitAsync = ref.watch(productInTransitByIdProvider(widget.productInTransitId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Просмотр Товара в пути'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          productInTransitAsync.when(
            data: (productInTransit) => productInTransit.status != ProductInTransitStatus.received.name &&
                                         productInTransit.status != ProductInTransitStatus.cancelled.name
                ? Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showReceiveDialog(context, productInTransit),
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
      body: productInTransitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: SelectableText.rich(TextSpan(text: 'Ошибка: $error', style: const TextStyle(color: Colors.red)))),
        data: (productInTransit) => SingleChildScrollView(
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
                    _infoRow('Название товара', productInTransit.name),
                    const SizedBox(height: 8),
                    _infoRow('Статус', _getProductInTransitStatus(productInTransit.status)),
                    const SizedBox(height: 8),
                    _infoRow('Запрошенное количество', '${productInTransit.quantity.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _infoRow('Фактическое количество', productInTransit.actualQuantity > 0 ? productInTransit.actualQuantity.toStringAsFixed(0) : '-'),
                    const SizedBox(height: 8),
                    _infoRow('Производитель', productInTransit.producer ?? '-'),
                    const SizedBox(height: 8),
                    _infoRow('Место отгрузки', productInTransit.shippingLocation ?? '-'),
                    const SizedBox(height: 8),
                    _infoRow('Дата отгрузки', productInTransit.shippingDate != null ? _formatDate(productInTransit.shippingDate!) : '-'),
                    const SizedBox(height: 8),
                    _infoRow('Ожидаемая дата прибытия', productInTransit.expectedArrivalDate != null ? _formatDate(productInTransit.expectedArrivalDate!) : '-'),
                    const SizedBox(height: 8),
                    _infoRow('Заметки', productInTransit.notes ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (productInTransit.warehouse != null) ...[
                _sectionCard(
                  context,
                  title: 'Информация о складе',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Название склада', productInTransit.warehouse!.name),
                      const SizedBox(height: 8),
                      _infoRow('Адрес склада', productInTransit.warehouse!.address),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (productInTransit.productTemplate != null) ...[
                _sectionCard(
                  context,
                  title: 'Информация о шаблоне товара',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Название шаблона', productInTransit.productTemplate!.name),
                      const SizedBox(height: 8),
                      _infoRow('Единица измерения', productInTransit.productTemplate!.unit ?? '-'),
                      if (productInTransit.productTemplate!.description != null) ...[
                        const SizedBox(height: 8),
                        _infoRow('Описание шаблона', productInTransit.productTemplate!.description!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (productInTransit.creator != null) ...[
                _sectionCard(
                  context,
                  title: 'Информация о создателе',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Имя создателя', productInTransit.creator!.name),
                      const SizedBox(height: 8),
                      _infoRow('Email создателя', productInTransit.creator!.email ?? '-'),
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

  String _getProductInTransitStatus(String status) {
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

  Future<void> _showReceiveDialog(BuildContext context, ProductInTransitEntity productInTransit) async {
    _actualQuantityController.text = productInTransit.quantity.toStringAsFixed(0);
    _notesController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Принять товар'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Товар: ${productInTransit.name}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actualQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Фактическое количество',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите фактическое количество';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Заметки (необязательно)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Принять', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final actualQuantity = double.parse(_actualQuantityController.text);
        final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

        final request = ReceiveProductInTransitRequest(
          actualQuantity: actualQuantity,
          notes: notes,
        );

        await ref.read(productsInTransitProvider.notifier).receiveProductInTransit(
          productInTransit.id,
          request,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${productInTransit.name}" принят'),
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
}







