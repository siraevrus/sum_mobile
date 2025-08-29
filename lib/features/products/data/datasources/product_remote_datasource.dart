import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/products/data/models/product_model.dart';

part 'product_remote_datasource.g.dart';

/// Абстрактный интерфейс для remote data source товаров
abstract class ProductRemoteDataSource {
  Future<LaravelPaginatedResponse<ProductModel>> getProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
    int? perPage,
    int? page,
  });

  Future<ProductModel> getProductById(int id);

  Future<ApiResponse<ProductModel>> createProduct({
    required int productTemplateId,
    required int warehouseId,
    required String name,
    required double quantity,
    String? description,
    Map<String, dynamic>? attributes,
    String? producer,
    String? arrivalDate,
    bool? isActive,
  });

  Future<ApiResponse<ProductModel>> updateProduct({
    required int id,
    String? name,
    double? quantity,
    String? description,
    Map<String, dynamic>? attributes,
    String? producer,
    String? arrivalDate,
    bool? isActive,
  });

  Future<ApiResponse<void>> deleteProduct(int id);

  Future<ApiResponse<Map<String, dynamic>>> getProductStats();

  Future<ApiResponse<List<ProductModel>>> getPopularProducts();

  Future<ApiResponse<List<ProductModel>>> exportProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
  });
}

/// Реализация remote data source для товаров
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSourceImpl(this._dio);

  @override
  Future<LaravelPaginatedResponse<ProductModel>> getProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
    int? perPage,
    int? page,
  }) async {
    try {
      print('🔵 ProductRemoteDataSource: Получаем список товаров');

      final queryParameters = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParameters['search'] = search;
      if (warehouseId != null) queryParameters['warehouse_id'] = warehouseId;
      if (templateId != null) queryParameters['template_id'] = templateId;
      if (producer != null && producer.isNotEmpty) queryParameters['producer'] = producer;
      if (inStock != null) queryParameters['in_stock'] = inStock;
      if (lowStock != null) queryParameters['low_stock'] = lowStock;
      if (active != null) queryParameters['active'] = active;
      if (perPage != null) queryParameters['per_page'] = perPage;
      if (page != null) queryParameters['page'] = page;

      final response = await _dio.get(
        '/products',
        queryParameters: queryParameters,
      );

      print('🟢 ProductRemoteDataSource: Получен ответ от API: ${response.statusCode}');

      return LaravelPaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка DIO: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      print('🔵 ProductRemoteDataSource: Получаем товар по ID: $id');

      final response = await _dio.get('/products/$id');

      print('🟢 ProductRemoteDataSource: Получен товар');

      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка получения товара: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<ProductModel>> createProduct({
    required int productTemplateId,
    required int warehouseId,
    required String name,
    required double quantity,
    String? description,
    Map<String, dynamic>? attributes,
    String? producer,
    String? arrivalDate,
    bool? isActive,
  }) async {
    try {
      print('🔵 ProductRemoteDataSource: Создаем товар: $name');

      final data = <String, dynamic>{
        'product_template_id': productTemplateId,
        'warehouse_id': warehouseId,
        'name': name,
        'quantity': quantity,
      };
      if (description != null) data['description'] = description;
      if (attributes != null) data['attributes'] = attributes;
      if (producer != null) data['producer'] = producer;
      if (arrivalDate != null) data['arrival_date'] = arrivalDate;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.post(
        '/products',
        data: data,
      );

      print('🟢 ProductRemoteDataSource: Товар создан');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка создания товара: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<ProductModel>> updateProduct({
    required int id,
    String? name,
    double? quantity,
    String? description,
    Map<String, dynamic>? attributes,
    String? producer,
    String? arrivalDate,
    bool? isActive,
  }) async {
    try {
      print('🔵 ProductRemoteDataSource: Обновляем товар: $id');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (quantity != null) data['quantity'] = quantity;
      if (description != null) data['description'] = description;
      if (attributes != null) data['attributes'] = attributes;
      if (producer != null) data['producer'] = producer;
      if (arrivalDate != null) data['arrival_date'] = arrivalDate;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.put(
        '/products/$id',
        data: data,
      );

      print('🟢 ProductRemoteDataSource: Товар обновлен');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка обновления товара: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<void>> deleteProduct(int id) async {
    try {
      print('🔵 ProductRemoteDataSource: Удаляем товар: $id');

      final response = await _dio.delete('/products/$id');

      print('🟢 ProductRemoteDataSource: Товар удален');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка удаления товара: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getProductStats() async {
    try {
      print('🔵 ProductRemoteDataSource: Получаем статистику товаров');

      final response = await _dio.get('/products/stats');

      print('🟢 ProductRemoteDataSource: Получена статистика товаров');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка получения статистики: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<List<ProductModel>>> getPopularProducts() async {
    try {
      print('🔵 ProductRemoteDataSource: Получаем популярные товары');

      final response = await _dio.get('/products/popular');

      print('🟢 ProductRemoteDataSource: Получены популярные товары');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List)
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка получения популярных товаров: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<List<ProductModel>>> exportProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
  }) async {
    try {
      print('🔵 ProductRemoteDataSource: Экспортируем товары');

      final queryParameters = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParameters['search'] = search;
      if (warehouseId != null) queryParameters['warehouse_id'] = warehouseId;
      if (templateId != null) queryParameters['template_id'] = templateId;
      if (producer != null && producer.isNotEmpty) queryParameters['producer'] = producer;
      if (inStock != null) queryParameters['in_stock'] = inStock;
      if (lowStock != null) queryParameters['low_stock'] = lowStock;
      if (active != null) queryParameters['active'] = active;

      final response = await _dio.get(
        '/products/export',
        queryParameters: queryParameters,
      );

      print('🟢 ProductRemoteDataSource: Товары экспортированы');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List)
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      print('🔴 ProductRemoteDataSource: Ошибка экспорта товаров: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Обработка DioException
  Never _handleDioException(DioException e) {
    if (e.response?.statusCode == 400) {
      throw Exception('Неверные данные: ${e.response?.data['message'] ?? e.message}');
    } else if (e.response?.statusCode == 401) {
      throw Exception('Не авторизован');
    } else if (e.response?.statusCode == 403) {
      throw Exception('Доступ запрещен');
    } else if (e.response?.statusCode == 404) {
      throw Exception('Товар не найден');
    } else if (e.response?.statusCode == 422) {
      throw Exception('Ошибка валидации: ${e.response?.data['message'] ?? e.message}');
    } else if (e.response?.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка сети: ${e.message}');
    }
  }
}

/// Provider для ProductRemoteDataSource
@riverpod
ProductRemoteDataSource productRemoteDataSource(
  ProductRemoteDataSourceRef ref,
) {
  final dio = ref.watch(dioClientProvider);
  return ProductRemoteDataSourceImpl(dio);
}
