import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/goods_in_transit/data/repositories/products_in_transit_repository.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

part 'products_in_transit_provider.g.dart';

/// Провайдер для списка товаров в пути
@riverpod
class ProductsInTransit extends _$ProductsInTransit {
  @override
  Future<List<ReceiptEntity>> build() async {
    return await _loadProductsInTransit();
  }

  Future<List<ReceiptEntity>> _loadProductsInTransit({
    int? page,
    int? perPage,
    String? search,
    int? warehouseId,
    String? sort,
  }) async {
    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      return await repository.getProductsInTransit(
        page: page,
        perPage: perPage,
        search: search,
        warehouseId: warehouseId,
        sort: sort ?? 'created_at', // По умолчанию сортируем по дате создания
      );
    } catch (e) {
      throw Exception('Ошибка загрузки товаров в пути: $e');
    }
  }

  /// Обновить список товаров в пути
  Future<void> refresh({
    int? warehouseId,
    String? sort,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProductsInTransit(
      warehouseId: warehouseId,
      sort: sort,
    ));
  }

  /// Принять товар в пути
  Future<void> receiveProduct(int id) async {
    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      await repository.receiveProductInTransit(id);
      // Обновляем список после успешного приема
      await refresh();
    } catch (e) {
      throw Exception('Ошибка приема товара: $e');
    }
  }

  /// Поиск товаров в пути
  Future<void> search(
    String? query, {
    int? warehouseId,
    String? sort,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProductsInTransit(
      search: query,
      warehouseId: warehouseId,
      sort: sort,
    ));
  }
}

/// Провайдер для получения товара в пути по ID
@riverpod
Future<ReceiptEntity> productInTransitById(
  ProductInTransitByIdRef ref,
  int id,
) async {
  final repository = ref.read(productsInTransitRepositoryProvider);
  return await repository.getProductInTransitById(id);
}
