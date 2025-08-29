import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/shared/models/popular_products_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

part 'products_provider.g.dart';

/// Состояния для списка товаров
sealed class ProductsState {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final PaginatedResponse<ProductModel> products;
  final ProductFilters? filters;
  
  const ProductsLoaded({
    required this.products,
    this.filters,
  });
}

class ProductsError extends ProductsState {
  final String message;
  
  const ProductsError(this.message);
}

/// Provider для управления товарами
@riverpod
class Products extends _$Products {
  @override
  ProductsState build() {
    // Автоматически загружаем товары при инициализации
    _loadProducts();
    return const ProductsLoading();
  }

  /// Загрузить товары с фильтрами
  Future<void> loadProducts([ProductFilters? filters]) async {
    state = const ProductsLoading();
    await _loadProducts(filters);
  }

  /// Перезагрузить товары с текущими фильтрами
  Future<void> refresh() async {
    final currentFilters = state is ProductsLoaded 
        ? (state as ProductsLoaded).filters 
        : null;
    await loadProducts(currentFilters);
  }

  /// Загрузить следующую страницу
  Future<void> loadNextPage() async {
    if (state is! ProductsLoaded) return;
    
    final currentState = state as ProductsLoaded;
    final currentPage = currentState.products.meta?.currentPage ?? 
                        currentState.products.pagination?.currentPage ?? 1;
    final lastPage = currentState.products.meta?.lastPage ?? 
                     currentState.products.pagination?.lastPage ?? 1;
    
    if (currentPage >= lastPage) return;
    
    try {
      final nextFilters = currentState.filters?.copyWith(
        page: currentPage + 1,
      ) ?? ProductFilters(page: currentPage + 1);
      
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      final nextPageResponse = await apiDataSource.getProducts(nextFilters);
      
      // Объединяем текущие товары с новыми
      final allProducts = [
        ...currentState.products.data,
        ...nextPageResponse.data,
      ];
      
      state = ProductsLoaded(
        products: PaginatedResponse(
          data: allProducts,
          links: nextPageResponse.links,
          meta: nextPageResponse.meta,
        ),
        filters: nextFilters,
      );
    } catch (e) {
      // При ошибке загрузки следующей страницы не меняем состояние
      print('Ошибка загрузки следующей страницы: $e');
    }
  }

  /// Поиск товаров
  Future<void> searchProducts(String query) async {
    final filters = ProductFilters(
      search: query.isNotEmpty ? query : null,
      page: 1,
    );
    await loadProducts(filters);
  }

  /// Фильтрация товаров
  Future<void> filterProducts(ProductFilters filters) async {
    await loadProducts(filters);
  }

  /// Приватный метод для загрузки товаров
  Future<void> _loadProducts([ProductFilters? filters]) async {
    try {
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      final response = await apiDataSource.getProducts(filters);
      
      state = ProductsLoaded(
        products: response,
        filters: filters,
      );
    } catch (e) {
      state = ProductsError('Ошибка загрузки товаров: $e');
    }
  }
}

/// Provider для статистики товаров
@riverpod
Future<ProductStats> productStats(ProductStatsRef ref) async {
  final apiDataSource = ref.watch(productsApiDataSourceProvider);
  return apiDataSource.getProductStats();
}

/// Provider для популярных товаров
@riverpod
Future<List<PopularProductModel>> popularProducts(PopularProductsRef ref) async {
  final apiDataSource = ref.watch(productsApiDataSourceProvider);
  return apiDataSource.getPopularProducts();
}

/// Provider для отдельного товара
@riverpod
Future<ProductModel> product(ProductRef ref, int productId) async {
  final apiDataSource = ref.watch(productsApiDataSourceProvider);
  return apiDataSource.getProduct(productId);
}

/// Provider для экспорта товаров
@riverpod
class ProductsExport extends _$ProductsExport {
  @override
  Future<List<ProductExportRow>?> build() async {
    return null; // Изначально не экспортируем
  }

  /// Экспортировать товары
  Future<void> exportProducts([ProductFilters? filters]) async {
    state = const AsyncValue.loading();
    
    try {
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      final exportData = await apiDataSource.exportProducts(filters);
      state = AsyncValue.data(exportData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Расширение для ProductFilters для copyWith  
extension ProductFiltersExtension on ProductFilters {
  ProductFilters copyWith({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
    int? perPage,
    int? page,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      warehouseId: warehouseId ?? this.warehouseId,
      templateId: templateId ?? this.templateId,
      producer: producer ?? this.producer,
      inStock: inStock ?? this.inStock,
      lowStock: lowStock ?? this.lowStock,
      active: active ?? this.active,
      perPage: perPage ?? this.perPage,
      page: page ?? this.page,
    );
  }
}
