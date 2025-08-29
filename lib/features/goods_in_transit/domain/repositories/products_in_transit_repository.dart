import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

/// Интерфейс репозитория для товаров в пути
abstract class ProductsInTransitRepository {
  Future<List<ReceiptEntity>> getProductsInTransit({
    int? page,
    int? perPage,
    String? search,
  });

  Future<ReceiptEntity> getProductInTransitById(int id);

  Future<ReceiptEntity> createProductInTransit(Map<String, dynamic> data);

  Future<ReceiptEntity> updateProductInTransit(int id, Map<String, dynamic> data);

  Future<ReceiptEntity> receiveProductInTransit(int id);
}



