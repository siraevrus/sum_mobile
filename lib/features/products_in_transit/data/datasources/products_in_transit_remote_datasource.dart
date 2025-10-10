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
      
      // Добавляем статус for_receipt по умолчанию для раздела "Товары в пути"
      if (!queryParams.containsKey('status')) {
        queryParams['status'] = 'for_receipt';
      }
      
      // include не нужен — API уже возвращает связанные объекты
      
      print('🔵 Запрос на /products (товары в пути) с параметрами: $queryParams');
      final response = await _dio.get('/products', queryParameters: queryParams);
      
      print('🔵 Ответ API /products (товары в пути): ${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}...');
      
      return PaginatedResponse<ProductInTransitModel>.fromJson(
        response.data,
        (json) {
          print('🔵 Парсинг товара в пути: $json');
          return ProductInTransitModel.fromJson(json as Map<String, dynamic>);
        },
      );
    } catch (e) {
      print('🔴 Ошибка в getProducts (товары в пути): $e');
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
      print('🔵 Создание товара в пути: ${request.toJson()}');
      final response = await _dio.post('/products', data: request.toJson());

      print('🔵 Ответ создания товара в пути: ${response.data}');
      print('🔵 Тип ответа: ${response.data.runtimeType}');

      // Проверяем структуру ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🔵 Ключи в ответе: ${data.keys.toList()}');

        // Пробуем разные варианты структуры ответа
        if (data.containsKey('product')) {
          print('🔵 Используем response.data[\'product\']');
          return ProductInTransitModel.fromJson(data['product']);
        } else if (data.containsKey('data')) {
          print('🔵 Используем response.data[\'data\']');
          return ProductInTransitModel.fromJson(data['data']);
        } else {
          print('🔵 Используем весь response.data');
          return ProductInTransitModel.fromJson(data);
        }
      } else {
        print('🔵 Ответ не является Map, используем как есть');
        return ProductInTransitModel.fromJson(response.data);
      }
    } catch (e) {
      print('🔴 Ошибка создания товара в пути: $e');
      print('🔴 Stack trace: ${StackTrace.current}');
      throw _handleError(e);
    }
  }

  /// Создание нескольких товаров в пути за один запрос
  Future<List<ProductInTransitModel>> createMultipleProducts(CreateMultipleProductsInTransitRequest request) async {
    try {
      print('🔵 Создание нескольких товаров в пути: ${request.toJson()}');
      final response = await _dio.post('/receipts', data: request.toJson());

      print('🔵 Ответ создания товаров в пути: ${response.data}');
      print('🔵 Тип ответа: ${response.data.runtimeType}');

      // Проверяем структуру ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🔵 Ключи в ответе: ${data.keys.toList()}');

        if (data.containsKey('data') && data['data'] is List) {
          print('🔵 Используем response.data[\'data\'] как массив');
          final productsList = data['data'] as List;
          return productsList.map((productJson) => ProductInTransitModel.fromJson(productJson)).toList();
        } else {
          print('🔵 Неожиданная структура ответа, пробуем парсить как есть');
          throw Exception('Неожиданная структура ответа API');
        }
      } else {
        print('🔵 Ответ не является Map');
        throw Exception('Неожиданный тип ответа API');
      }
    } catch (e) {
      print('🔴 Ошибка создания товаров в пути: $e');
      print('🔴 Stack trace: ${StackTrace.current}');
      throw _handleError(e);
    }
  }

  @override
  Future<ProductInTransitModel> updateProduct(int id, UpdateProductInTransitRequest request) async {
    try {
      print('🔵 Обновление товара в пути $id: ${request.toJson()}');
      final response = await _dio.put('/products/$id', data: request.toJson());
      
      print('🔵 Ответ обновления товара в пути: ${response.data}');
      
      return ProductInTransitModel.fromJson(response.data['product']);
    } catch (e) {
      print('🔴 Ошибка обновления товара в пути: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      print('🔵 Удаление товара в пути $id');
      await _dio.delete('/products/$id');
      print('🔵 Товар в пути $id успешно удален');
    } catch (e) {
      print('🔴 Ошибка удаления товара в пути: $e');
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
