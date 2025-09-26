import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/shared/models/paginated_response.dart';

part 'products_in_transit_remote_datasource.g.dart';

@riverpod
ProductsInTransitRemoteDataSource productsInTransitRemoteDataSource(ProductsInTransitRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductsInTransitRemoteDataSource(dio);
}

class ProductsInTransitRemoteDataSource {
  final Dio _dio;

  ProductsInTransitRemoteDataSource(this._dio);

  /// Получить список товаров в пути
  Future<ProductInTransitResponse> getProductsInTransit({
    int? page,
    int? perPage,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      print('🌐 Запрос к API: /products-in-transit с параметрами: $queryParams');
      
      final response = await _dio.get(
        '/products-in-transit',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📡 Ответ API: ${response.statusCode}');
      print('📄 Данные ответа: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final result = ProductInTransitResponse.fromJson(response.data as Map<String, dynamic>);
        print('🔄 Парсинг успешен, товаров: ${result.data.length}');
        return result;
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет доступа к товарам в пути');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Товары в пути не найдены');
      } else {
        throw Exception('Ошибка загрузки товаров в пути: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Получить товар в пути по ID
  Future<ProductInTransitModel> getProductInTransitById(int id) async {
    try {
      final response = await _dio.get('/products-in-transit/$id');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          return ProductInTransitModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        return ProductInTransitModel.fromJson(data);
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет доступа к товару в пути');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Товар в пути не найден');
      } else {
        throw Exception('Ошибка загрузки товара в пути: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Создать товар в пути
  Future<List<ProductInTransitModel>> createProductInTransit(CreateProductInTransitRequest request) async {
    try {
      final response = await _dio.post('/products-in-transit', data: request.toJson());
      if (response.data is Map<String, dynamic>) {
        final responseModel = ProductInTransitResponse.fromJson(response.data as Map<String, dynamic>);
        return responseModel.data;
      }
      throw Exception('Неожиданный формат ответа API при создании товара в пути');
    } on DioException catch (e) {
      throw Exception('Ошибка создания товара в пути: ${e.message}');
    } catch (e) {
      throw Exception('Неожиданная ошибка при создании товара в пути: $e');
    }
  }

  /// Принять товар (изменить статус на received)
  Future<void> receiveProductInTransit(int productId, ReceiveProductInTransitRequest request) async {
    try {
      await _dio.post('/products-in-transit/$productId/receive', data: request.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет прав на принятие товара в пути');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Товар в пути не найден');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Нельзя принять товар в пути в текущем статусе');
      } else {
        throw Exception('Ошибка принятия товара в пути: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }
}
