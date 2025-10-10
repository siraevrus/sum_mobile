import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';

part 'products_in_transit_provider.freezed.dart';
part 'products_in_transit_provider.g.dart';

/// Состояние списка товаров в пути
@freezed
class ProductsInTransitState with _$ProductsInTransitState {
  const factory ProductsInTransitState.loading() = ProductsInTransitLoading;
  const factory ProductsInTransitState.loaded({
    required PaginatedResponse<ProductInTransitModel> products,
    ProductInTransitFilters? filters,
  }) = ProductsInTransitLoaded;
  const factory ProductsInTransitState.error(String message) = ProductsInTransitError;
}

/// Provider для управления товарами в пути
@riverpod
class ProductsInTransit extends _$ProductsInTransit {
  @override
  ProductsInTransitState build() {
    // Автоматически загружаем товары при инициализации
    _loadProducts();
    return const ProductsInTransitState.loading();
  }

  /// Загрузить товары с фильтрами
  Future<void> loadProducts([ProductInTransitFilters? filters]) async {
    state = const ProductsInTransitState.loading();
    await _loadProducts(filters);
  }

  /// Перезагрузить товары с текущими фильтрами
  Future<void> refresh() async {
    final currentFilters = state is ProductsInTransitLoaded 
        ? (state as ProductsInTransitLoaded).filters 
        : null;
    await loadProducts(currentFilters);
  }

  /// Загрузить следующую страницу
  Future<void> loadNextPage() async {
    if (state is! ProductsInTransitLoaded) return;
    
    final currentState = state as ProductsInTransitLoaded;
    final currentPage = currentState.products.pagination?.currentPage ?? 1;
    final lastPage = currentState.products.pagination?.lastPage ?? 1;
    
    if (currentPage >= lastPage) return;
    
    try {
      final nextFilters = currentState.filters?.copyWith(
        page: currentPage + 1,
      ) ?? ProductInTransitFilters(page: currentPage + 1);
      
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      final nextPageResponse = await apiDataSource.getProducts(nextFilters);
      
      final currentProducts = currentState.products.data;
      final newProducts = nextPageResponse.data;
      
      final updatedProducts = PaginatedResponse<ProductInTransitModel>(
        data: [...currentProducts, ...newProducts],
        success: nextPageResponse.success,
        pagination: nextPageResponse.pagination,
      );
      
      state = ProductsInTransitState.loaded(
        products: updatedProducts,
        filters: nextFilters,
      );
    } catch (e) {
      print('🔴 Ошибка загрузки следующей страницы: $e');
    }
  }

  /// Поиск товаров
  Future<void> searchProducts(String query) async {
    final filters = ProductInTransitFilters(
      search: query.isNotEmpty ? query : null,
      page: 1,
    );
    await loadProducts(filters);
  }

  /// Фильтрация товаров
  Future<void> filterProducts(ProductInTransitFilters filters) async {
    await loadProducts(filters);
  }

  /// Создание товара
  Future<ProductInTransitModel> createProduct(CreateProductInTransitRequest request) async {
    try {
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      final newProduct = await apiDataSource.createProduct(request);
      
      // Обновляем список товаров
      await refresh();
      
      return newProduct;
    } catch (e) {
      throw Exception('Ошибка создания товара: $e');
    }
  }

  /// Создание нескольких товаров
  Future<List<ProductInTransitModel>> createMultipleProducts(CreateMultipleProductsInTransitRequest request) async {
    try {
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      final newProducts = await apiDataSource.createMultipleProducts(request);
      
      // Обновляем список товаров
      await refresh();
      
      return newProducts;
    } catch (e) {
      throw Exception('Ошибка создания товаров: $e');
    }
  }

  /// Обновление товара
  Future<ProductInTransitModel> updateProduct(int id, UpdateProductInTransitRequest request) async {
    try {
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      final updatedProduct = await apiDataSource.updateProduct(id, request);
      
      // Обновляем список товаров
      await refresh();
      
      return updatedProduct;
    } catch (e) {
      throw Exception('Ошибка обновления товара: $e');
    }
  }

  /// Удаление товара
  Future<void> deleteProduct(int id) async {
    try {
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      await apiDataSource.deleteProduct(id);
      
      // Обновляем список товаров
      await refresh();
    } catch (e) {
      throw Exception('Ошибка удаления товара: $e');
    }
  }

  /// Приватный метод для загрузки товаров
  Future<void> _loadProducts([ProductInTransitFilters? filters]) async {
    try {
      final apiDataSource = ref.read(productsInTransitRemoteDataSourceProvider);
      final response = await apiDataSource.getProducts(filters);
      
      state = ProductsInTransitState.loaded(
        products: response,
        filters: filters,
      );
    } catch (e, stackTrace) {
      print('🔴 Ошибка загрузки товаров в пути: $e');
      print('🔴 Stack trace: $stackTrace');
      state = ProductsInTransitState.error('Ошибка загрузки товаров в пути: $e');
    }
  }
}

/// Provider для отдельного товара в пути
@riverpod
Future<ProductInTransitModel> productInTransit(ProductInTransitRef ref, int productId) async {
  final apiDataSource = ref.watch(productsInTransitRemoteDataSourceProvider);
  return await apiDataSource.getProduct(productId);
}
