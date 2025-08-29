import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/goods_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/features/goods_in_transit/domain/repositories/products_in_transit_repository.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

part 'products_in_transit_repository.g.dart';

@riverpod
ProductsInTransitRepository productsInTransitRepository(
  ProductsInTransitRepositoryRef ref,
) {
  final dataSource = ref.read(productsInTransitRemoteDataSourceProvider);
  return ProductsInTransitRepositoryImpl(dataSource);
}

class ProductsInTransitRepositoryImpl implements ProductsInTransitRepository {
  final ProductsInTransitRemoteDataSource _dataSource;

  ProductsInTransitRepositoryImpl(this._dataSource);

  @override
  Future<List<ReceiptEntity>> getProductsInTransit({
    int? page,
    int? perPage,
    String? search,
  }) async {
    final models = await _dataSource.getProductsInTransit(
      page: page,
      perPage: perPage,
      search: search,
    );
    return models.map((model) => model.toReceiptEntity()).toList();
  }

  @override
  Future<ReceiptEntity> getProductInTransitById(int id) async {
    final model = await _dataSource.getProductInTransitById(id);
    return model.toReceiptEntity();
  }

  @override
  Future<ReceiptEntity> createProductInTransit(Map<String, dynamic> data) async {
    final model = await _dataSource.createProductInTransit(data);
    return model.toReceiptEntity();
  }

  @override
  Future<ReceiptEntity> updateProductInTransit(int id, Map<String, dynamic> data) async {
    final model = await _dataSource.updateProductInTransit(id, data);
    return model.toReceiptEntity();
  }

  @override
  Future<ReceiptEntity> receiveProductInTransit(int id) async {
    final model = await _dataSource.receiveProductInTransit(id);
    return model.toReceiptEntity();
  }
}
