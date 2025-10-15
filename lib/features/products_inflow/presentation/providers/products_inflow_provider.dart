import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/products_inflow_remote_datasource.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';

part 'products_inflow_provider.freezed.dart';
part 'products_inflow_provider.g.dart';

/// Состояние списка товаров
@freezed
class ProductsInflowState with _$ProductsInflowState {
  const factory ProductsInflowState.loading() = ProductsInflowLoading;
  const factory ProductsInflowState.loaded({
    required PaginatedResponse<ProductInflowModel> products,
    ProductInflowFilters? filters,
  }) = ProductsInflowLoaded;
  const factory ProductsInflowState.error(String message) = ProductsInflowError;
}

/// Provider для управления товарами в поступлениях
@riverpod
class ProductsInflow extends _$ProductsInflow {
  @override
  ProductsInflowState build() {
    // Автоматически загружаем товары при инициализации
    _loadProducts();
    return const ProductsInflowState.loading();
  }

  /// Загрузить товары с фильтрами
  Future<void> loadProducts([ProductInflowFilters? filters]) async {
    state = const ProductsInflowState.loading();
    await _loadProducts(filters);
  }

  /// Перезагрузить товары с текущими фильтрами
  Future<void> refresh() async {
    final currentFilters = state is ProductsInflowLoaded 
        ? (state as ProductsInflowLoaded).filters 
        : null;
    await loadProducts(currentFilters);
  }

  /// Загрузить следующую страницу
  Future<void> loadNextPage() async {
    if (state is! ProductsInflowLoaded) return;
    
    final currentState = state as ProductsInflowLoaded;
    final currentPage = currentState.products.pagination?.currentPage ?? 1;
    final lastPage = currentState.products.pagination?.lastPage ?? 1;
    
    if (currentPage >= lastPage) return;
    
    try {
      final nextFilters = currentState.filters?.copyWith(
        page: currentPage + 1,
      ) ?? ProductInflowFilters(page: currentPage + 1);
      
      final apiDataSource = ref.read(productsInflowRemoteDataSourceProvider);
      final nextPageResponse = await apiDataSource.getProducts(nextFilters);
      
      // Объединяем текущие товары с новыми
      final allProducts = [
        ...currentState.products.data,
        ...nextPageResponse.data,
      ];
      
      state = ProductsInflowState.loaded(
        products: nextPageResponse.copyWith(data: allProducts),
        filters: nextFilters,
      );
    } catch (e) {
    }
  }

  /// Поиск товаров
  Future<void> searchProducts(String query) async {
    final filters = ProductInflowFilters(
      search: query.isNotEmpty ? query : null,
      page: 1,
    );
    await loadProducts(filters);
  }

  /// Фильтрация товаров
  Future<void> filterProducts(ProductInflowFilters filters) async {
    await loadProducts(filters);
  }

  /// Создание товара
  Future<ProductInflowModel> createProduct(CreateProductInflowRequest request) async {
    try {
      final apiDataSource = ref.read(productsInflowRemoteDataSourceProvider);
      final newProduct = await apiDataSource.createProduct(request);
      
      // Обновляем список товаров
      await refresh();
      
      return newProduct;
    } catch (e) {
      throw Exception('Ошибка создания товара: $e');
    }
  }

  /// Обновление товара
  Future<ProductInflowModel> updateProduct(int id, UpdateProductInflowRequest request) async {
    try {
      final apiDataSource = ref.read(productsInflowRemoteDataSourceProvider);
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
      final apiDataSource = ref.read(productsInflowRemoteDataSourceProvider);
      await apiDataSource.deleteProduct(id);
      
      // Обновляем список товаров
      await refresh();
    } catch (e) {
      throw Exception('Ошибка удаления товара: $e');
    }
  }

  /// Приватный метод для загрузки товаров
  Future<void> _loadProducts([ProductInflowFilters? filters]) async {
    try {
      final apiDataSource = ref.read(productsInflowRemoteDataSourceProvider);
      final response = await apiDataSource.getProducts(filters);
      
      state = ProductsInflowState.loaded(
        products: response,
        filters: filters,
      );
    } catch (e, stackTrace) {
      state = ProductsInflowState.error('Ошибка загрузки товаров: $e');
    }
  }
}

/// Provider для отдельного товара
@riverpod
Future<ProductInflowModel> productInflow(ProductInflowRef ref, int productId) async {
  final apiDataSource = ref.watch(productsInflowRemoteDataSourceProvider);
  return apiDataSource.getProduct(productId);
}
