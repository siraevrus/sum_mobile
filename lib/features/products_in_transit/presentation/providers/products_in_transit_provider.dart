import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/data/repositories/products_in_transit_repository_impl.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';

part 'products_in_transit_provider.g.dart';

@riverpod
class ProductsInTransit extends _$ProductsInTransit {
  @override
  Future<List<ProductInTransitEntity>> build() async {
    return await _loadProductsInTransit();
  }

  Future<List<ProductInTransitEntity>> _loadProductsInTransit({String? status, String? search}) async {
    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      return await repository.getProductsInTransit(status: status, search: search);
    } catch (e) {
      throw Exception('Ошибка загрузки товаров в пути: $e');
    }
  }

  /// Обновить список товаров в пути
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProductsInTransit());
  }

  /// Поиск товаров в пути
  Future<void> searchProductsInTransit(String query) async {
    if (query.isEmpty) {
      await refresh();
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _loadProductsInTransit(search: query);
    });
  }

  /// Фильтр по статусу
  Future<void> filterByStatus(String? status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _loadProductsInTransit(status: status);
    });
  }

  /// Создать товар в пути
  Future<List<ProductInTransitEntity>> createProductInTransit(CreateProductInTransitRequest request) async {
    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      final newProductsInTransit = await repository.createProductInTransit(request);
      await refresh();
      return newProductsInTransit;
    } catch (e) {
      throw Exception('Ошибка создания товара в пути: $e');
    }
  }

  /// Принять товар
  Future<void> receiveProductInTransit(int productId, ReceiveProductInTransitRequest request) async {
    try {
      final repository = ref.read(productsInTransitRepositoryProvider);
      await repository.receiveProductInTransit(productId, request);
      // Обновляем список после принятия
      await refresh();
    } catch (e) {
      throw Exception('Ошибка принятия товара в пути: $e');
    }
  }
}

@riverpod
Future<ProductInTransitEntity> productInTransitById(ProductInTransitByIdRef ref, int id) async {
  final repository = ref.read(productsInTransitRepositoryProvider);
  return await repository.getProductInTransitById(id);
}

