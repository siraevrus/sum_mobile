import 'package:flutter/material.dart';
import '../../domain/entities/receipt_entity.dart';
import 'package:intl/intl.dart';

class ReceiptCard extends StatelessWidget {
  final ReceiptEntity receipt;
  final VoidCallback? onTap;
  final VoidCallback? onReceive;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
    this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(context),
                      ],
                    ),
                  ),
                  if (receipt.status == ReceiptStatus.forReceipt && onReceive != null)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: onReceive,
                      tooltip: 'Принять товар',
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Количество',
                '${receipt.quantity} шт.',
                Icons.inventory_2_outlined,
              ),
              if (receipt.shippingLocation != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Место отгрузки',
                  receipt.shippingLocation!,
                  Icons.location_on_outlined,
                ),
              ],
              if (receipt.expectedArrivalDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Ожидаемая дата прибытия',
                  DateFormat('dd.MM.yyyy').format(receipt.expectedArrivalDate!),
                  Icons.schedule_outlined,
                ),
              ],
              if (receipt.transportNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Номер транспорта',
                  receipt.transportNumber!,
                  Icons.local_shipping_outlined,
                ),
              ],
              if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Заметки',
                  receipt.notes!,
                  Icons.note_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    String statusText;

    switch (receipt.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}