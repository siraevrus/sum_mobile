import 'package:sum_warehouse/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/domain/repositories/sales_repository.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

/// Реализация репозитория продаж
class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource _remoteDataSource;

  SalesRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedResponse<SaleModel>> getSales({
    int page = 1,
    int perPage = 15,
    SaleFilters? filters,
  }) async {
    return await _remoteDataSource.getSales(
      page: page,
      perPage: perPage,
      filters: filters,
    );
  }

  @override
  Future<SaleModel> getSale(int id) async {
    return await _remoteDataSource.getSale(id);
  }

  @override
  Future<SaleModel> createSale(CreateSaleRequest request) async {
    return await _remoteDataSource.createSale(request);
  }

  @override
  Future<SaleModel> updateSale(int id, UpdateSaleRequest request) async {
    return await _remoteDataSource.updateSale(id, request);
  }

  @override
  Future<void> deleteSale(int id) async {
    return await _remoteDataSource.deleteSale(id);
  }

  @override
  Future<void> processSale(int id) async {
    return await _remoteDataSource.processSale(id);
  }

  @override
  Future<void> cancelSale(int id) async {
    print('🔵 SalesRepository: Запрос на отмену продажи ID: $id');
    return await _remoteDataSource.cancelSale(id);
  }
}
