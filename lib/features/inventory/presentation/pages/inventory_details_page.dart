import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_entity.dart';
import 'package:sum_warehouse/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/stock_movement_form_page.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Экран деталей остатков товара
class InventoryDetailsPage extends ConsumerWidget {
  final InventoryEntity inventory;

  const InventoryDetailsPage({
    super.key,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementHistoryAsync = ref.watch(movementHistoryProvider(inventory.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Остатки товара'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StockMovementFormPage(
                    inventory: inventory,
                  ),
                ),
              );
            },
            tooltip: 'Создать движение',
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о товаре
            _buildProductCard(),
            const SizedBox(height: 16),
            
            // Информация об остатках
            _buildStockCard(),
            const SizedBox(height: 16),
            
            // Информация о складе
            _buildWarehouseCard(),
            const SizedBox(height: 24),
            
            // История движений
            const Text(
              'История движений',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            movementHistoryAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => _buildMovementError(error.toString()),
              data: (movements) => movements.isEmpty
                  ? _buildEmptyMovements()
                  : _buildMovementsList(movements),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Товар',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              inventory.product?.name ?? 'Неизвестный товар',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            if (inventory.product?.producer != null) ...[
              const SizedBox(height: 4),
              Text(
                'Производитель: ${inventory.product!.producer}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            
            if (inventory.product?.unit != null) ...[
              const SizedBox(height: 4),
              Text(
                'Единица измерения: ${inventory.product!.unit}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Остатки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStockInfo(
                    'Общий остаток',
                    inventory.quantity.toString(),
                    Icons.inventory,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockInfo(
                    'В резерве',
                    inventory.reservedQuantity.toString(),
                    Icons.lock,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStockInfo(
                    'Доступно',
                    inventory.availableQuantity.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockInfo(
                    'Мин. уровень',
                    inventory.minStockLevel?.toString() ?? 'Не задан',
                    Icons.warning,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            
            if (inventory.fillPercentage != null) ...[
              const SizedBox(height: 16),
              Text(
                'Заполненность: ${inventory.fillPercentage!.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: inventory.fillPercentage! / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  inventory.fillPercentage! > 80 
                      ? AppColors.error 
                      : inventory.fillPercentage! > 60 
                          ? AppColors.warning 
                          : AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warehouse, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Склад',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              inventory.warehouse?.name ?? 'Склад №${inventory.warehouseId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            if (inventory.warehouse?.address != null) ...[
              const SizedBox(height: 4),
              Text(
                inventory.warehouse!.address,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = inventory.stockStatus;
    Color color;
    
    switch (status) {
      case StockStatus.inStock:
        color = AppColors.success;
        break;
      case StockStatus.lowStock:
        color = AppColors.warning;
        break;
      case StockStatus.outOfStock:
        color = AppColors.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMovementError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ошибка загрузки истории: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMovements() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Нет движений',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'История движений товара пуста',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementsList(List<StockMovementEntity> movements) {
    return Column(
      children: movements.map((movement) => _buildMovementCard(movement)).toList(),
    );
  }

  Widget _buildMovementCard(StockMovementEntity movement) {
    final isPositive = movement.quantity > 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.type.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (movement.reason != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      movement.reason!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (movement.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${movement.createdAt!.day}.${movement.createdAt!.month}.${movement.createdAt!.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}${movement.quantity}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '= ${movement.newQuantity}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


