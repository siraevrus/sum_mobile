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
  /// GET /api/receipts с фильтром по статусу
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
        '/receipts',
        queryParameters: queryParams,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // Поддержка success/data/pagination обертки
        final List<dynamic> productsList = (data['data'] as List?) ?? <dynamic>[];
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
  /// GET /api/receipts/{id}
  Future<ProductInTransitModel> getProductInTransitById(int id) async {
    try {
      final response = await _dio.get('/receipts/$id');

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
  /// POST /api/receipts
  Future<ProductInTransitModel> createProductInTransit(Map<String, dynamic> data) async {
    try {
      // Добавляем статус "в пути" для новых товаров
      final receiptData = Map<String, dynamic>.from(data);
      receiptData['status'] = 'in_transit';
      // document_path по спецификации — массив строк, оставляем как есть
      final response = await _dio.post('/receipts', data: receiptData);

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        // Поддерживаем различные форматы ответа
        if (map.containsKey('product') && map['product'] is Map<String, dynamic>) {
          return ProductInTransitModel.fromJson(map['product'] as Map<String, dynamic>);
        }
        if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
          return ProductInTransitModel.fromJson(map['data'] as Map<String, dynamic>);
        }
        // Прямой объект
        return ProductInTransitModel.fromJson(map);
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
  /// PUT /api/receipts/{id}
  Future<ProductInTransitModel> updateProductInTransit(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/receipts/$id', data: data);

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
  /// POST /api/receipts/{id}/receive - принимаем товар
  Future<ProductInTransitModel> receiveProductInTransit(int id, {int? actualQuantity, String? notes}) async {
    try {
      final requestData = <String, dynamic>{};
      if (actualQuantity != null) requestData['actual_quantity'] = actualQuantity;
      if (notes != null) requestData['notes'] = notes;
      
      final response = await _dio.post('/receipts/$id/receive', data: requestData);

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
