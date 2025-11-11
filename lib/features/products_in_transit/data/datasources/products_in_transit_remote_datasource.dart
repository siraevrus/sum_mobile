import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';

part 'products_in_transit_remote_datasource.g.dart';

/// Интерфейс для работы с API товаров в пути
abstract class ProductsInTransitRemoteDataSource {
  Future<PaginatedResponse<ProductInTransitModel>> getProducts([ProductInTransitFilters? filters]);
  Future<ProductInTransitModel> getProduct(int id);
  Future<ProductInTransitModel> createProduct(CreateProductInTransitRequest request);
  Future<List<ProductInTransitModel>> createMultipleProducts(CreateMultipleProductsInTransitRequest request);
  Future<ProductInTransitModel> updateProduct(int id, UpdateProductInTransitRequest request);
  Future<void> deleteProduct(int id);
}

/// Реализация API источника данных для товаров в пути
class ProductsInTransitRemoteDataSourceImpl implements ProductsInTransitRemoteDataSource {
  final Dio _dio;
  
  ProductsInTransitRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<ProductInTransitModel>> getProducts([ProductInTransitFilters? filters]) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {'page': 1, 'per_page': 15};
      
      // Используем эндпоинт /products-in-transit для получения товаров в пути
      // Убираем фильтр по статусу, так как эндпоинт уже возвращает только товары в пути
      queryParams.remove('status');
      
      // include не нужен — API уже возвращает связанные объекты
      
      final response = await _dio.get('/products-in-transit', queryParameters: queryParams);
      
      
      return PaginatedResponse<ProductInTransitModel>.fromJson(
        response.data,
        (json) {
          return ProductInTransitModel.fromJson(json as Map<String, dynamic>);
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInTransitModel> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id', queryParameters: {
        'include': 'template,warehouse,creator,producer'
      });
      return ProductInTransitModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInTransitModel> createProduct(CreateProductInTransitRequest request) async {
    try {
      final response = await _dio.post('/products', data: request.toJson());


      // Проверяем структуру ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Пробуем разные варианты структуры ответа
        if (data.containsKey('product')) {
          return ProductInTransitModel.fromJson(data['product']);
        } else if (data.containsKey('data')) {
          return ProductInTransitModel.fromJson(data['data']);
        } else {
          return ProductInTransitModel.fromJson(data);
        }
      } else {
        return ProductInTransitModel.fromJson(response.data);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Создание нескольких товаров в пути за один запрос
  Future<List<ProductInTransitModel>> createMultipleProducts(CreateMultipleProductsInTransitRequest request) async {
    try {
      final response = await _dio.post('/receipts', data: request.toJson());


      // Проверяем структуру ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('data') && data['data'] is List) {
          final productsList = data['data'] as List;
          return productsList.map((productJson) => ProductInTransitModel.fromJson(productJson)).toList();
        } else {
          throw Exception('Неожиданная структура ответа API');
        }
      } else {
        throw Exception('Неожиданный тип ответа API');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInTransitModel> updateProduct(int id, UpdateProductInTransitRequest request) async {
    try {
      final response = await _dio.put('/products/$id', data: request.toJson());
      
      // Проверяем структуру ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Пробуем разные варианты структуры ответа
        if (data.containsKey('product')) {
          return ProductInTransitModel.fromJson(data['product']);
        } else if (data.containsKey('data')) {
          return ProductInTransitModel.fromJson(data['data']);
        } else {
          return ProductInTransitModel.fromJson(data);
        }
      } else {
        return ProductInTransitModel.fromJson(response.data);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Обработка ошибок API
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Ошибка соединения с сервером');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Неизвестная ошибка сервера';
          return Exception('Ошибка сервера ($statusCode): $message');
        case DioExceptionType.cancel:
          return Exception('Запрос отменен');
        case DioExceptionType.unknown:
          return Exception('Ошибка сети: ${error.message}');
        default:
          return Exception('Неизвестная ошибка: ${error.message}');
      }
    }
    return Exception('Неожиданная ошибка: $error');
  }
}

/// Provider для API источника данных товаров в пути
@riverpod
ProductsInTransitRemoteDataSource productsInTransitRemoteDataSource(ProductsInTransitRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductsInTransitRemoteDataSourceImpl(dio);
}
