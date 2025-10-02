import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

part 'products_in_transit_provider.g.dart';

/// Состояния для товаров в пути
sealed class ProductsInTransitState {}

class ProductsInTransitLoading extends ProductsInTransitState {}

class ProductsInTransitLoaded extends ProductsInTransitState {
  final PaginatedResponse<ProductModel> products;
  final ProductFilters? filters;

  ProductsInTransitLoaded({
    required this.products,
    this.filters,
  });
}

class ProductsInTransitError extends ProductsInTransitState {
  final String message;

  ProductsInTransitError(this.message);
}

/// Provider для товаров в пути (статус in_stock)
@riverpod
class ProductsInTransit extends _$ProductsInTransit {
  @override
  ProductsInTransitState build() {
    // Начинаем с пустого состояния, загрузка будет вызвана явно
    return ProductsInTransitLoading();
  }

  /// Загрузка товаров в пути
  Future<void> loadProductsInTransit([ProductFilters? filters]) async {
    try {
      state = ProductsInTransitLoading();
      
      print('🔵 Начинаем загрузку товаров в пути...');
      
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      
      // Создаем фильтры для товаров в пути
      final transitFilters = ProductFilters(
        status: 'in_stock', // Фильтруем только товары со статусом in_stock
        search: filters?.search,
        warehouseId: filters?.warehouseId,
        templateId: filters?.templateId,
        producer: filters?.producer,
        page: filters?.page ?? 1,
        perPage: filters?.perPage ?? 15,
      );
      
      print('🔵 Фильтры для товаров в пути: ${transitFilters.toQueryParams()}');
      
      final response = await apiDataSource.getProducts(transitFilters);
      
      print('🔵 Получено товаров в пути: ${response.data.length}');
      
      state = ProductsInTransitLoaded(
        products: response,
        filters: transitFilters,
      );
    } catch (e, stackTrace) {
      print('🔴 Ошибка загрузки товаров в пути: $e');
      print('🔴 Stack trace: $stackTrace');
      
      // Создаем более информативное сообщение об ошибке
      String errorMessage = 'Ошибка загрузки товаров в пути';
      if (e.toString().contains('401')) {
        errorMessage = 'Ошибка авторизации. Войдите в систему заново.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'API не найдено. Проверьте настройки сервера.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Ошибка сервера. Попробуйте позже.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Нет подключения к интернету.';
      } else {
        errorMessage = 'Неизвестная ошибка: ${e.toString()}';
      }
      
      state = ProductsInTransitError(errorMessage);
    }
  }

  /// Обновление списка
  Future<void> refresh() async {
    final currentState = state;
    final currentFilters = currentState is ProductsInTransitLoaded 
        ? currentState.filters 
        : null;
    await loadProductsInTransit(currentFilters);
  }

  /// Поиск товаров в пути
  Future<void> searchProducts(String query) async {
    final filters = ProductFilters(
      search: query.isNotEmpty ? query : null,
      status: 'in_stock',
      page: 1,
    );
    await loadProductsInTransit(filters);
  }

  /// Фильтрация товаров в пути
  Future<void> filterProducts(ProductFilters filters) async {
    final transitFilters = filters.copyWith(status: 'in_stock');
    await loadProductsInTransit(transitFilters);
  }

  /// Создание нового товара в пути
  Future<ProductModel?> createProductInTransit(CreateProductRequest request) async {
    try {
      print('🔵 Создание товара в пути: $request');
      print('🔵 calculated_volume в запросе товара в пути: ${request.calculatedVolume}');
      
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      
      // Убеждаемся, что статус установлен в in_stock
      final transitRequest = request.copyWith(status: 'in_stock');
      
      final newProduct = await apiDataSource.createProduct(transitRequest);
      
      // Обновляем список после создания
      await refresh();
      
      return newProduct;
    } catch (e) {
      print('🔴 Ошибка создания товара в пути: $e');
      rethrow;
    }
  }

  /// Обновление товара в пути
  Future<ProductModel?> updateProductInTransit(int id, UpdateProductRequest request) async {
    try {
      print('🔵 Обновляем товар в пути с ID: $id');
      print('🔵 calculated_volume в запросе обновления товара в пути: ${request.calculatedVolume}');
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      final updatedProduct = await apiDataSource.updateProduct(id, request);
      
      // Обновляем состояние списка
      final currentState = state;
      if (currentState is ProductsInTransitLoaded) {
        final updatedProducts = currentState.products.data.map((product) {
          return product.id == id ? updatedProduct : product;
        }).toList();
        
        state = ProductsInTransitLoaded(
          products: currentState.products.copyWith(data: updatedProducts),
          filters: currentState.filters,
        );
      }
      
      print('🔵 Товар в пути обновлен успешно');
      return updatedProduct;
    } catch (e, stackTrace) {
      print('🔴 Ошибка обновления товара в пути: $e');
      print('🔴 Stack trace: $stackTrace');
      throw e;
    }
  }

  /// Удаление товара в пути
  Future<void> deleteProductInTransit(int id) async {
    try {
      print('🔵 Удаляем товар в пути с ID: $id');
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      await apiDataSource.deleteProduct(id);
      
      // Обновляем состояние списка - убираем удаленный товар
      final currentState = state;
      if (currentState is ProductsInTransitLoaded) {
        final filteredProducts = currentState.products.data.where((product) => product.id != id).toList();
        
        // Получаем текущий total из meta или pagination
        final currentTotal = currentState.products.meta?.total ?? 
                            currentState.products.pagination?.total ?? 
                            filteredProducts.length;
        
        // Создаем новую мета-информацию с обновленным total
        final updatedMeta = currentState.products.meta?.copyWith(total: currentTotal - 1);
        final updatedPagination = currentState.products.pagination?.copyWith(total: currentTotal - 1);
        
        state = ProductsInTransitLoaded(
          products: currentState.products.copyWith(
            data: filteredProducts,
            meta: updatedMeta,
            pagination: updatedPagination,
          ),
          filters: currentState.filters,
        );
      }
      
      print('🔵 Товар в пути удален успешно');
    } catch (e, stackTrace) {
      print('🔴 Ошибка удаления товара в пути: $e');
      print('🔴 Stack trace: $stackTrace');
      throw e;
    }
  }

  /// Загрузка следующей страницы
  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is! ProductsInTransitLoaded) return;
    
    final currentFilters = currentState.filters;
    if (currentFilters == null) return;
    
    // Проверяем, есть ли еще страницы
    final currentPage = currentFilters.page;
    final totalPages = currentState.products.pagination?.lastPage ?? 
                       currentState.products.meta?.lastPage ?? 1;
    
    if (currentPage >= totalPages) return;
    
    try {
      final nextFilters = currentFilters.copyWith(page: currentPage + 1);
      await loadProductsInTransit(nextFilters);
    } catch (e) {
      // При ошибке загрузки следующей страницы не меняем состояние
      print('Ошибка загрузки следующей страницы: $e');
    }
  }
}
