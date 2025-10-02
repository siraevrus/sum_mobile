import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_form_page.dart';

/// Страница детального просмотра товара
class ProductInflowDetailPage extends ConsumerWidget {
  final ProductInflowModel product;

  const ProductInflowDetailPage({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name ?? 'Без названия'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductInflowFormPage(product: product),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            _buildSection(
              title: 'Основная информация',
              children: [
                _buildInfoRow('Название', product.name ?? 'Без названия'),
                if (product.description != null && product.description!.isNotEmpty)
                  _buildInfoRow('Описание', product.description!),
                _buildInfoRow('Количество', '${product.quantity} ${product.template?.unit ?? ''}'),
                _buildInfoRow('Объем', product.calculatedVolume ?? '0'),
                _buildInfoRow('Статус', _getStatusText(product.status)),
                _buildInfoRow('Активен', product.isActive ? 'Да' : 'Нет'),
              ],
            ),

            const SizedBox(height: 24),

            // Связанные объекты
            _buildSection(
              title: 'Связанные объекты',
              children: [
                _buildInfoRow('Склад', product.warehouse?.name ?? 'Не указан'),
                _buildInfoRow('Производитель', product.producer?.name ?? 'Не указан'),
                _buildInfoRow('Создатель', product.creator?.name ?? 'Не указан'),
                _buildInfoRow('Шаблон товара', product.template?.name ?? 'Не указан'),
              ],
            ),

            const SizedBox(height: 24),

            // Транспортная информация
            _buildSection(
              title: 'Транспортная информация',
              children: [
                _buildInfoRow('Номер транспорта', product.transportNumber ?? 'Не указан'),
                _buildInfoRow('Место отгрузки', product.shippingLocation ?? 'Не указано'),
                _buildInfoRow('Дата отгрузки', product.shippingDate != null 
                    ? _formatDate(product.shippingDate!) 
                    : 'Не указана'),
                _buildInfoRow('Ожидаемая дата прибытия', product.expectedArrivalDate != null 
                    ? _formatDate(product.expectedArrivalDate!) 
                    : 'Не указана'),
                _buildInfoRow('Фактическая дата прибытия', product.actualArrivalDate != null 
                    ? _formatDate(product.actualArrivalDate!) 
                    : 'Не указана'),
                _buildInfoRow('Дата поступления', product.arrivalDate != null 
                    ? _formatDate(product.arrivalDate!) 
                    : 'Не указана'),
              ],
            ),

            const SizedBox(height: 24),

            // Атрибуты товара
            if (product.attributes.isNotEmpty)
              _buildSection(
                title: 'Атрибуты товара',
                children: product.attributes.entries
                    .map((entry) => _buildInfoRow(entry.key, entry.value.toString()))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // Документы
            if (product.documentPath.isNotEmpty)
              _buildSection(
                title: 'Документы',
                children: [
                  ...product.documentPath.map((path) => _buildDocumentItem(context, path)),
                ],
              ),

            const SizedBox(height: 24),

            // Заметки
            if (product.notes != null && product.notes!.isNotEmpty)
              _buildSection(
                title: 'Заметки',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      product.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Системная информация
            _buildSection(
              title: 'Системная информация',
              children: [
                _buildInfoRow('ID', product.id.toString()),
                _buildInfoRow('ID шаблона', product.productTemplateId.toString()),
                _buildInfoRow('ID склада', product.warehouseId.toString()),
                _buildInfoRow('ID создателя', product.createdBy.toString()),
                _buildInfoRow('Дата создания', _formatDateTime(product.createdAt)),
                _buildInfoRow('Дата обновления', _formatDateTime(product.updatedAt)),
              ],
            ),

            const SizedBox(height: 24),

            // Коррекции
            if (product.correction != null || product.correctionStatus != null)
              _buildSection(
                title: 'Коррекции',
                children: [
                  if (product.correction != null)
                    _buildInfoRow('Коррекция', product.correction!),
                  if (product.correctionStatus != null)
                    _buildInfoRow('Статус коррекции', product.correctionStatus!),
                  if (product.revisedAt != null)
                    _buildInfoRow('Дата пересмотра', _formatDateTime(product.revisedAt!)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path.split('/').last,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Реализовать открытие документа
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие документа будет реализовано')),
              );
            },
            icon: Icon(
              Icons.open_in_new,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_stock':
        return 'На складе';
      case 'for_receipt':
        return 'На приемке';
      case 'in_transit':
        return 'В пути';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
