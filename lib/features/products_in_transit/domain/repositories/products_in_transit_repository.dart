import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart'; // Для CreateProductInTransitRequest и ReceiveProductInTransitRequest

abstract class ProductsInTransitRepository {
  Future<List<ProductInTransitEntity>> getProductsInTransit({
    int? page,
    int? perPage,
    String? status,
    String? search,
  });

  Future<ProductInTransitEntity> getProductInTransitById(int id);

  Future<List<ProductInTransitEntity>> createProductInTransit(CreateProductInTransitRequest request);

  Future<void> receiveProductInTransit(int productId, ReceiveProductInTransitRequest request);
}
