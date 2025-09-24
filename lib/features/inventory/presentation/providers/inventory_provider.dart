import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';

part 'inventory_provider.g.dart';

/// Provider для получения списка остатков с кешированием (новое API)
@riverpod
class StocksList extends _$StocksList {
  @override
  Future<List<StockModel>> build() async {
    return await _fetchStocks();
  }

  Future<List<StockModel>> _fetchStocks({
    int? warehouseId,
    bool? lowStock,
    int page = 1,
    int perPage = 15,
  }) async {
    final datasource = ref.read(inventoryRemoteDataSourceProvider);
    
    return await datasource.getStocks(
      warehouseId: warehouseId,
      lowStock: lowStock,
      page: page,
      perPage: perPage,
    );
  }

  /// Обновить список остатков
  Future<void> refresh({
    int? warehouseId,
    bool? lowStock,
    int page = 1,
    int perPage = 15,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStocks(
      warehouseId: warehouseId,
      lowStock: lowStock,
      page: page,
      perPage: perPage,
    ));
  }
}

/// Provider для получения конкретного остатка
@riverpod
class StockDetails extends _$StockDetails {
  @override
  Future<StockModel> build(String stockId) async {
    final datasource = ref.read(inventoryRemoteDataSourceProvider);
    return await datasource.getStockById(stockId);
  }
}

/// Provider для создания движения товара
@riverpod
class StockMovementNotifier extends _$StockMovementNotifier {
  @override
  Future<void> build() async {
    // Инициализация
  }
  
  /// Создать движение товара
  Future<void> createStockMovement({
    required String stockId,
    required String type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  }) async {
    state = const AsyncLoading();
    
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      
      await datasource.createStockMovement(
        stockId: stockId,
        type: type,
        quantity: quantity,
        reason: reason,
        documentNumber: documentNumber,
        notes: notes,
      );
      
      state = const AsyncData(null);
      
      // Обновляем список остатков
      ref.invalidate(stocksListProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
  
  /// Корректировать остатки
  Future<void> adjustStock({
    required String stockId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    state = const AsyncLoading();
    
    try {
      final datasource = ref.read(inventoryRemoteDataSourceProvider);
      
      await datasource.adjustStock(
        stockId: stockId,
        newQuantity: newQuantity,
        reason: reason,
        notes: notes,
      );
      
      state = const AsyncData(null);
      
      // Обновляем список остатков
      ref.invalidate(stocksListProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
