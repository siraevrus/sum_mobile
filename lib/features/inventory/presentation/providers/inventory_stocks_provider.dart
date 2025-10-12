import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/inventory_models.dart' as old_models;
import '../../../../shared/models/product_model.dart';
import '../../data/datasources/inventory_stocks_remote_datasource.dart';
import '../../domain/entities/inventory_aggregation_entity.dart';

part 'inventory_stocks_provider.g.dart';

/// Состояние для остатков на складах
sealed class InventoryStocksState {}

class InventoryStocksLoading extends InventoryStocksState {}

class InventoryStocksLoaded extends InventoryStocksState {
  final List<ProductModel> stocks;
  final old_models.InventoryPaginationModel? pagination;
  
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
      final stocks = await dataSource.getStocks(
        page: page,
        perPage: perPage,
        warehouseId: warehouseId,
        status: status ?? 'in_stock',
      );
      
      state = InventoryStocksLoaded(
        stocks: stocks,
        pagination: null, // Пока не используем пагинацию
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
    return await dataSource.getWarehouses();
  }

  /// Обновить список складов
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      return await dataSource.getWarehouses();
    });
  }
}

/// Provider для компаний
@riverpod
class InventoryCompanies extends _$InventoryCompanies {
  @override
  Future<List<InventoryCompanyModel>> build() async {
    final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
    return await dataSource.getCompanies();
  }

  /// Обновить список компаний
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
      return await dataSource.getCompanies();
    });
  }
}

/// Provider для деталей производителя
@riverpod
Future<PaginatedStockDetails> producerDetails(
  ProducerDetailsRef ref,
  int producerId, {
  int page = 1,
  int perPage = 15,
}) async {
  final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
  return await dataSource.getProducerDetails(producerId, page: page, perPage: perPage);
}

/// Provider для деталей склада
@riverpod
Future<PaginatedStockDetails> warehouseDetails(
  WarehouseDetailsRef ref,
  int warehouseId, {
  int page = 1,
  int perPage = 15,
}) async {
  final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
  return await dataSource.getWarehouseDetails(warehouseId, page: page, perPage: perPage);
}

/// Provider для деталей компании
@riverpod
Future<PaginatedStockDetails> companyDetails(
  CompanyDetailsRef ref,
  int companyId, {
  int page = 1,
  int perPage = 15,
}) async {
  final dataSource = ref.read(inventoryStocksRemoteDataSourceProvider);
  return await dataSource.getCompanyDetails(companyId, page: page, perPage: perPage);
}
