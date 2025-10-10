import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/acceptance/data/datasources/acceptance_remote_datasource.dart';
import 'package:sum_warehouse/features/acceptance/data/models/acceptance_model.dart';

part 'acceptance_provider.freezed.dart';
part 'acceptance_provider.g.dart';

/// Состояние списка товаров приемки
@freezed
class AcceptanceState with _$AcceptanceState {
  const factory AcceptanceState.loading() = AcceptanceLoading;
  const factory AcceptanceState.loaded({
    required PaginatedResponse<AcceptanceModel> products,
    AcceptanceFilters? filters,
  }) = AcceptanceLoaded;
  const factory AcceptanceState.error(String message) = AcceptanceError;
}

/// Provider для управления товарами приемки
@riverpod
class AcceptanceNotifier extends _$AcceptanceNotifier {
  @override
  AcceptanceState build() {
    // Автоматически загружаем товары при инициализации
    _loadProducts();
    return const AcceptanceState.loading();
  }

  /// Загрузить товары с фильтрами
  Future<void> loadProducts([AcceptanceFilters? filters]) async {
    state = const AcceptanceState.loading();
    await _loadProducts(filters);
  }

  /// Перезагрузить товары с текущими фильтрами
  Future<void> refresh() async {
    final currentFilters = state is AcceptanceLoaded 
        ? (state as AcceptanceLoaded).filters 
        : null;
    await loadProducts(currentFilters);
  }

  /// Загрузить следующую страницу
  Future<void> loadNextPage() async {
    if (state is! AcceptanceLoaded) return;
    
    final currentState = state as AcceptanceLoaded;
    final currentPage = currentState.products.pagination?.currentPage ?? 1;
    final lastPage = currentState.products.pagination?.lastPage ?? 1;
    
    if (currentPage >= lastPage) return;
    
    try {
      final nextFilters = currentState.filters?.copyWith(
        page: currentPage + 1,
      ) ?? AcceptanceFilters(page: currentPage + 1);
      
      final apiDataSource = ref.read(acceptanceRemoteDataSourceProvider);
      final nextPageResponse = await apiDataSource.getProducts(nextFilters);
      
      final currentProducts = currentState.products.data;
      final newProducts = nextPageResponse.data;
      
      final updatedProducts = PaginatedResponse<AcceptanceModel>(
        data: [...currentProducts, ...newProducts],
        success: nextPageResponse.success,
        pagination: nextPageResponse.pagination,
      );
      
      state = AcceptanceState.loaded(
        products: updatedProducts,
        filters: nextFilters,
      );
    } catch (e) {
      print('🔴 Ошибка загрузки следующей страницы приемки: $e');
    }
  }

  /// Поиск товаров
  Future<void> searchProducts(String query) async {
    final filters = AcceptanceFilters(
      search: query.isNotEmpty ? query : null,
      page: 1,
    );
    await loadProducts(filters);
  }

  /// Фильтрация товаров
  Future<void> filterProducts(AcceptanceFilters filters) async {
    await loadProducts(filters);
  }

  /// Создание товара
  Future<AcceptanceModel> createProduct(CreateAcceptanceRequest request) async {
    try {
      final apiDataSource = ref.read(acceptanceRemoteDataSourceProvider);
      final newProduct = await apiDataSource.createProduct(request);
      
      // Обновляем список товаров
      await refresh();
      
      return newProduct;
    } catch (e) {
      throw Exception('Ошибка создания товара приемки: $e');
    }
  }

  /// Обновление товара
  Future<AcceptanceModel> updateProduct(int id, UpdateAcceptanceRequest request) async {
    try {
      final apiDataSource = ref.read(acceptanceRemoteDataSourceProvider);
      final updatedProduct = await apiDataSource.updateProduct(id, request);
      
      // Обновляем список товаров
      await refresh();
      
      return updatedProduct;
    } catch (e) {
      throw Exception('Ошибка обновления товара приемки: $e');
    }
  }

  /// Удаление товара
  Future<void> deleteProduct(int id) async {
    try {
      final apiDataSource = ref.read(acceptanceRemoteDataSourceProvider);
      await apiDataSource.deleteProduct(id);
      
      // Обновляем список товаров
      await refresh();
    } catch (e) {
      throw Exception('Ошибка удаления товара приемки: $e');
    }
  }

  /// Приватный метод для загрузки товаров
  Future<void> _loadProducts([AcceptanceFilters? filters]) async {
    try {
      final apiDataSource = ref.read(acceptanceRemoteDataSourceProvider);
      final response = await apiDataSource.getProducts(filters);
      
      state = AcceptanceState.loaded(
        products: response,
        filters: filters,
      );
    } catch (e, stackTrace) {
      print('🔴 Ошибка загрузки товаров приемки: $e');
      print('🔴 Stack trace: $stackTrace');
      state = AcceptanceState.error('Ошибка загрузки товаров приемки: $e');
    }
  }
}

/// Provider для отдельного товара приемки
@riverpod
Future<AcceptanceModel> acceptanceProduct(AcceptanceProductRef ref, int productId) async {
  final apiDataSource = ref.watch(acceptanceRemoteDataSourceProvider);
  return await apiDataSource.getProduct(productId);
}
