import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';

part 'products_inflow_remote_datasource.g.dart';

/// Интерфейс для работы с API товаров
abstract class ProductsInflowRemoteDataSource {
  Future<PaginatedResponse<ProductInflowModel>> getProducts([ProductInflowFilters? filters]);
  Future<ProductInflowModel> getProduct(int id);
  Future<ProductInflowModel> createProduct(CreateProductInflowRequest request);
  Future<ProductInflowModel> updateProduct(int id, UpdateProductInflowRequest request);
  Future<void> deleteProduct(int id);
}

/// Реализация API источника данных для товаров
class ProductsInflowRemoteDataSourceImpl implements ProductsInflowRemoteDataSource {
  final Dio _dio;
  
  ProductsInflowRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<ProductInflowModel>> getProducts([ProductInflowFilters? filters]) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {'page': 1, 'per_page': 15};
      
      // Добавляем статус in_stock по умолчанию для раздела "Поступление товаров"
      if (!queryParams.containsKey('status')) {
        queryParams['status'] = 'in_stock';
      }
      
      // include не нужен — API уже возвращает связанные объекты
      
      final response = await _dio.get('/products', queryParameters: queryParams);
      
      
      return PaginatedResponse<ProductInflowModel>.fromJson(
        response.data,
        (json) {
          return ProductInflowModel.fromJson(json as Map<String, dynamic>);
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInflowModel> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id', queryParameters: {
        'include': 'template,warehouse,creator,producer'
      });
      return ProductInflowModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInflowModel> createProduct(CreateProductInflowRequest request) async {
    try {
      final response = await _dio.post('/products', data: request.toJson());
      
      
      return ProductInflowModel.fromJson(response.data['product']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInflowModel> updateProduct(int id, UpdateProductInflowRequest request) async {
    try {
      final response = await _dio.put('/products/$id', data: request.toJson());
      
      
      return ProductInflowModel.fromJson(response.data['product']);
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

/// Provider для API источника данных
@riverpod
ProductsInflowRemoteDataSource productsInflowRemoteDataSource(ProductsInflowRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductsInflowRemoteDataSourceImpl(dio);
}
