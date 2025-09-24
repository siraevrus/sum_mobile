import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/shared/models/popular_products_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

part 'products_api_datasource.g.dart';

/// API источник данных для товаров
abstract class ProductsApiDataSource {
  /// Получить список товаров с пагинацией
  Future<PaginatedResponse<ProductModel>> getProducts([ProductFilters? filters]);
  
  /// Получить товар по ID
  Future<ProductModel> getProduct(int id);
  
  /// Создать товар
  Future<ProductModel> createProduct(CreateProductRequest request);
  
  /// Обновить товар
  Future<ProductModel> updateProduct(int id, UpdateProductRequest request);
  
  /// Удалить товар
  Future<void> deleteProduct(int id);
  
  /// Получить статистику товаров
  Future<ProductStats> getProductStats();
  
  /// Получить популярные товары
  Future<List<PopularProductModel>> getPopularProducts();
  
  /// Экспорт товаров
  Future<List<ProductExportRow>> exportProducts([ProductFilters? filters]);
}

/// Реализация API источника данных для товаров
class ProductsApiDataSourceImpl implements ProductsApiDataSource {
  final Dio _dio;
  
  ProductsApiDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<ProductModel>> getProducts([ProductFilters? filters]) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {'page': 1, 'per_page': 15};
      
      final response = await _dio.get('/products', queryParameters: queryParams);
      
      return PaginatedResponse<ProductModel>.fromJson(
        response.data,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductModel> createProduct(CreateProductRequest request) async {
    try {
      print('🔵 Создание товара: ${request.toJson()}');
      final response = await _dio.post('/products', data: request.toJson());
      
      print('🔵 Ответ API создания товара: ${response.data}');
      
      // API может возвращать разные форматы
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        // Если есть вложенная структура с product (для товаров)
        if (responseData.containsKey('product') && responseData['product'] != null) {
          return ProductModel.fromJson(responseData['product'] as Map<String, dynamic>);
        }
        // Если есть вложенная структура с data
        else if (responseData.containsKey('data') && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data'] as Map<String, dynamic>);
        }
        // Если данные товара находятся в корне ответа
        else {
          return ProductModel.fromJson(responseData);
        }
      }
      
      throw Exception('Неожиданный формат ответа API');
    } catch (e) {
      print('🔴 Ошибка создания товара: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<ProductModel> updateProduct(int id, UpdateProductRequest request) async {
    try {
      print('🔵 Обновление товара $id: ${request.toJson()}');
      final response = await _dio.put('/products/$id', data: request.toJson());
      
      print('🔵 Ответ API обновления товара: ${response.data}');
      
      // API может возвращать разные форматы
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        // Если есть вложенная структура с product (для товаров)
        if (responseData.containsKey('product') && responseData['product'] != null) {
          return ProductModel.fromJson(responseData['product'] as Map<String, dynamic>);
        }
        // Если есть вложенная структура с data
        else if (responseData.containsKey('data') && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data'] as Map<String, dynamic>);
        }
        // Если данные товара находятся в корне ответа
        else {
          return ProductModel.fromJson(responseData);
        }
      }
      
      throw Exception('Неожиданный формат ответа API');
    } catch (e) {
      print('🔴 Ошибка обновления товара: $e');
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

  @override
  Future<ProductStats> getProductStats() async {
    try {
      final response = await _dio.get('/products/stats');
      return ProductStats.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<PopularProductModel>> getPopularProducts() async {
    try {
      final response = await _dio.get('/products/popular');
      
      // According to OpenAPI spec, API should return array directly
      if (response.data is List) {
        final productsData = response.data as List;
        return productsData
            .map((json) => PopularProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Fallback: check if wrapped in success/data structure (old format)
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final productsData = responseData['data'] as List;
          return productsData
              .map((json) => PopularProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      
      throw Exception('Unexpected API response format for popular products');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ProductExportRow>> exportProducts([ProductFilters? filters]) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {};
      
      final response = await _dio.get('/products/export', queryParameters: queryParams);
      
      // According to OpenAPI spec, export endpoint returns binary data (file)
      // For now, handle as JSON array if that's what API actually returns
      if (response.data is List) {
        final productsData = response.data as List;
        return productsData
            .map((json) => ProductExportRow.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Fallback: check if wrapped in data structure
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final productsData = responseData['data'] as List;
          return productsData
              .map((json) => ProductExportRow.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      
      throw Exception('Unexpected API response format for export products');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Обработка ошибок API
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return Exception('Необходима авторизация');
        case 403:
          return Exception('Доступ запрещен');
        case 404:
          return Exception('Товар не найден');
        case 422:
          final errorData = error.response?.data;
          if (errorData != null) {
            try {
              final apiError = ApiErrorModel.fromJson(errorData);
              return Exception(apiError.message);
            } catch (_) {
              return Exception('Ошибка валидации данных');
            }
          }
          return Exception('Ошибка валидации данных');
        case 500:
          return Exception('Внутренняя ошибка сервера');
        default:
          return Exception('Ошибка сети: ${error.message}');
      }
    }
    
    return Exception('Неизвестная ошибка: $error');
  }
}

/// Provider для API источника данных товаров
@riverpod
ProductsApiDataSource productsApiDataSource(ProductsApiDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductsApiDataSourceImpl(dio);
}
