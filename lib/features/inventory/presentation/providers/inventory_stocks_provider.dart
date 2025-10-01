import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../data/datasources/inventory_stocks_remote_datasource.dart';

part 'inventory_stocks_provider.g.dart';

/// Состояние для остатков на складах
sealed class InventoryStocksState {}

class InventoryStocksLoading extends InventoryStocksState {}

class InventoryStocksLoaded extends InventoryStocksState {
  final List<InventoryStockModel> stocks;
  final InventoryPaginationModel? pagination;
  
  InventoryStocksLoaded({
    required this.stocks,
    this.pagination,
  });
}

class InventoryStocksError extends InventoryStocksState {
  final String message;
  
  InventoryStocksError(this.message);
}

/// Provider для остатков на складах
@riverpod
class InventoryStocks extends _$InventoryStocks {
  @override
  InventoryStocksState build() {
    return InventoryStocksLoading();
  }

  /// Загрузить остатки
  Future<void> loadStocks({
    int page = 1,
    int perPage = 15,
    int? warehouseId,
    String? status,
  }) async {
    try {
      state = InventoryStocksLoading();
      
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      final response = await dataSource.getStocks(
        page: page,
        perPage: perPage,
        warehouseId: warehouseId,
        status: status ?? 'in_stock',
      );
      
      state = InventoryStocksLoaded(
        stocks: response.data,
        pagination: response.pagination,
      );
    } catch (e) {
      state = InventoryStocksError(e.toString());
    }
  }

  /// Обновить данные
  Future<void> refresh({
    int? warehouseId,
    String? status,
  }) async {
    await loadStocks(
      warehouseId: warehouseId,
      status: status,
    );
  }
}

/// Provider для производителей
@riverpod
class InventoryProducers extends _$InventoryProducers {
  @override
  Future<List<InventoryProducerModel>> build() async {
    final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
    return await dataSource.getProducers();
  }

  /// Обновить список производителей
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      return await dataSource.getProducers();
    });
  }
}

/// Provider для складов
@riverpod
class InventoryWarehouses extends _$InventoryWarehouses {
  @override
  Future<List<InventoryWarehouseModel>> build() async {
    final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
    final response = await dataSource.getWarehouses();
    return response.data;
  }

  /// Обновить список складов
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      final response = await dataSource.getWarehouses();
      return response.data;
    });
  }
}

/// Provider для компаний
@riverpod
class InventoryCompanies extends _$InventoryCompanies {
  @override
  Future<List<InventoryCompanyModel>> build() async {
    final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
    final response = await dataSource.getCompanies();
    return response.data;
  }

  /// Обновить список компаний
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      final response = await dataSource.getCompanies();
      return response.data;
    });
  }
}
