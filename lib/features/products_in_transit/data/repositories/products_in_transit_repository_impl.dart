import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/repositories/products_in_transit_repository.dart';

part 'products_in_transit_repository_impl.g.dart';

@riverpod
ProductsInTransitRepository productsInTransitRepository(ProductsInTransitRepositoryRef ref) {
  final dataSource = ref.watch(productsInTransitRemoteDataSourceProvider);
  return ProductsInTransitRepositoryImpl(dataSource);
}

class ProductsInTransitRepositoryImpl implements ProductsInTransitRepository {
  final ProductsInTransitRemoteDataSource _dataSource;

  ProductsInTransitRepositoryImpl(this._dataSource);

  @override
  Future<List<ProductInTransitEntity>> getProductsInTransit({
    int? page,
    int? perPage,
    String? status,
    String? search,
  }) async {
    final response = await _dataSource.getProductsInTransit(
      page: page,
      perPage: perPage,
      status: status,
      search: search,
    );
    return response.data.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ProductInTransitEntity> getProductInTransitById(int id) async {
    final model = await _dataSource.getProductInTransitById(id);
    return model.toEntity();
  }

  @override
  Future<List<ProductInTransitEntity>> createProductInTransit(CreateProductInTransitRequest request) async {
    final models = await _dataSource.createProductInTransit(request);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> receiveProductInTransit(int productId, ReceiveProductInTransitRequest request) async {
    return await _dataSource.receiveProductInTransit(productId, request);
  }
}
