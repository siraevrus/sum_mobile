import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/reception/data/models/receipt_model.dart';
import 'package:sum_warehouse/features/goods_in_transit/data/models/product_in_transit_model.dart';

part 'products_in_transit_remote_datasource.g.dart';

/// Remote data source для товаров в пути (products-in-transit)
@riverpod
ProductsInTransitRemoteDataSource productsInTransitRemoteDataSource(
  ProductsInTransitRemoteDataSourceRef ref,
) {
  final dio = ref.read(dioClientProvider);
  return ProductsInTransitRemoteDataSource(dio);
}

class ProductsInTransitRemoteDataSource {
  final Dio _dio;

  ProductsInTransitRemoteDataSource(this._dio);

  /// Получить список товаров в пути
  /// GET /api/products с фильтром по статусу
  Future<List<ProductInTransitModel>> getProductsInTransit({
    int? page,
    int? perPage,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': 'in_transit', // Фильтр по статусу "в пути"
      };
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productsList = data['data'] ?? [];
        
        return productsList.map((json) => ProductInTransitModel.fromJson(json as Map<String, dynamic>)).toList();
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
  /// GET /api/products/{id}
  Future<ProductInTransitModel> getProductInTransitById(int id) async {
    try {
      final response = await _dio.get('/products/$id');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Проверяем, если ответ в формате {success: true, data: {...}}
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return ProductInTransitModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        
        // Если прямой объект
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

  /// Создать новый товар в пути
  /// POST /api/products
  Future<ProductInTransitModel> createProductInTransit(Map<String, dynamic> data) async {
    try {
      // Добавляем статус "в пути" для новых товаров
      final productData = Map<String, dynamic>.from(data);
      productData['status'] = 'in_transit';
      
      final response = await _dio.post('/products', data: productData);

      if (response.data is Map<String, dynamic>) {
        return ProductInTransitModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет прав на создание товара');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Ошибка валидации данных');
      } else {
        throw Exception('Ошибка создания товара: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Обновить товар в пути
  /// PUT /api/products/{id}
  Future<ProductInTransitModel> updateProductInTransit(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/products/$id', data: data);

      if (response.data is Map<String, dynamic>) {
        return ProductInTransitModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет прав на редактирование товара');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Товар не найден');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Ошибка валидации данных');
      } else {
        throw Exception('Ошибка обновления товара: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Принять товар в пути
  /// PUT /api/products/{id} - обновляем статус на "received"
  Future<ProductInTransitModel> receiveProductInTransit(int id) async {
    try {
      final response = await _dio.put('/products/$id', data: {
        'status': 'received',
        'arrival_date': DateTime.now().toIso8601String(),
      });

      if (response.data is Map<String, dynamic>) {
        return ProductInTransitModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет прав на прием товара');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Товар в пути не найден');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Товар нельзя принять в текущем статусе');
      } else {
        throw Exception('Ошибка приема товара: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }
}
