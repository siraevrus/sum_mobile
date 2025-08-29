import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_entity.dart';

part 'inventory_provider.g.dart';

/// Provider для получения списка остатков с кешированием
@riverpod
class InventoryList extends _$InventoryList {
  @override
  Future<List<InventoryEntity>> build() async {
    return await _fetchInventory();
  }

  Future<List<InventoryEntity>> _fetchInventory({
    int? warehouseId,
    String? status,
    bool? needsRestock,
    String? search,
  }) async {
    final datasource = ref.read(inventoryRemoteDataSourceProvider);
    
    return await datasource.getInventoryList(
      warehouseId: warehouseId,
      status: status,
      needsRestock: needsRestock,
      search: search,
    );
  }

  /// Обновить список с фильтрами
  Future<void> updateFilters({
    int? warehouseId,
    String? status,
    bool? needsRestock,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final inventory = await _fetchInventory(
        warehouseId: warehouseId,
        status: status,
        needsRestock: needsRestock,
        search: search,
      );
      state = AsyncValue.data(inventory);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить данные
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider для получения истории движений товара
final movementHistoryProvider = FutureProvider.family<List<StockMovementEntity>, int>((ref, productId) async {
  final datasource = ref.read(inventoryRemoteDataSourceProvider);
  
  return await datasource.getMovementHistory(productId);
});

/// Provider для создания движения товара
final stockMovementNotifierProvider = AsyncNotifierProvider<StockMovementNotifier, void>(() {
  return StockMovementNotifier();
});

class StockMovementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Инициализация
  }
  
  /// Создать движение товара
  Future<void> createStockMovement({
    required int inventoryId,
    required MovementType type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  }) async {
    state = const AsyncLoading();
    
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      
      await datasource.createStockMovementByInventory(
        inventoryId: inventoryId,
        type: type.code,
        quantity: quantity,
        reason: reason,
        documentNumber: documentNumber,
        notes: notes,
      );
      
      state = const AsyncData(null);
      
      // Обновляем список остатков
      ref.invalidate(inventoryListProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
