import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';

part 'product_template_remote_datasource.g.dart';

/// Абстрактный интерфейс для remote data source шаблонов товаров
abstract class ProductTemplateRemoteDataSource {
  Future<PaginatedResponse<ProductTemplateModel>> getProductTemplates({
    bool? isActive,
    String? search,
    String? sort,
    String? order,
    int? perPage,
    int? page,
  });

  Future<ApiResponse<ProductTemplateModel>> getProductTemplateById(int id);

  Future<ApiResponse<ProductTemplateModel>> createProductTemplate({
    required String name,
    required String unit,
    String? description,
    String? formula,
    bool? isActive,
  });

  Future<ApiResponse<ProductTemplateModel>> updateProductTemplate({
    required int id,
    String? name,
    String? unit,
    String? description,
    String? formula,
    bool? isActive,
  });

  Future<ApiResponse<void>> deleteProductTemplate(int id);

  Future<ApiResponse<void>> activateProductTemplate(int id);

  Future<ApiResponse<void>> deactivateProductTemplate(int id);

  Future<ApiResponse<List<String>>> getAvailableUnits();
  
  /// Получить атрибуты шаблона товара
  Future<List<TemplateAttributeModel>> getTemplateAttributes(int templateId);
}

/// Реализация remote data source для шаблонов товаров
class ProductTemplateRemoteDataSourceImpl implements ProductTemplateRemoteDataSource {
  final Dio _dio;

  ProductTemplateRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<ProductTemplateModel>> getProductTemplates({
    bool? isActive,
    String? search,
    String? sort,
    String? order,
    int? perPage,
    int? page,
  }) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Получаем список шаблонов товаров');

      final queryParameters = <String, dynamic>{};
      if (isActive != null) queryParameters['is_active'] = isActive;
      if (search != null && search.isNotEmpty) queryParameters['search'] = search;
      if (sort != null) queryParameters['sort'] = sort;
      if (order != null) queryParameters['order'] = order;
      if (perPage != null) queryParameters['per_page'] = perPage;
      if (page != null) queryParameters['page'] = page;

      final response = await _dio.get(
        '/product-templates',
        queryParameters: queryParameters,
      );

      print('🟢 ProductTemplateRemoteDataSource: Получен ответ от API: ${response.statusCode}');

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка DIO: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<ProductTemplateModel>> getProductTemplateById(int id) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Получаем шаблон товара по ID: $id');

      final response = await _dio.get('/product-templates/$id');

      print('🟢 ProductTemplateRemoteDataSource: Получен шаблон товара');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка получения шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<ProductTemplateModel>> createProductTemplate({
    required String name,
    required String unit,
    String? description,
    String? formula,
    bool? isActive,
  }) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Создаем шаблон товара: $name');

      final data = <String, dynamic>{
        'name': name,
        'unit': unit,
      };
      if (description != null) data['description'] = description;
      if (formula != null) data['formula'] = formula;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.post(
        '/product-templates',
        data: data,
      );

      print('🟢 ProductTemplateRemoteDataSource: Шаблон товара создан');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка создания шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<ProductTemplateModel>> updateProductTemplate({
    required int id,
    String? name,
    String? unit,
    String? description,
    String? formula,
    bool? isActive,
  }) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Обновляем шаблон товара: $id');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (unit != null) data['unit'] = unit;
      if (description != null) data['description'] = description;
      if (formula != null) data['formula'] = formula;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.put(
        '/product-templates/$id',
        data: data,
      );

      print('🟢 ProductTemplateRemoteDataSource: Шаблон товара обновлен');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка обновления шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<void>> deleteProductTemplate(int id) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Удаляем шаблон товара: $id');

      final response = await _dio.delete('/product-templates/$id');

      print('🟢 ProductTemplateRemoteDataSource: Шаблон товара удален');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка удаления шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<void>> activateProductTemplate(int id) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Активируем шаблон товара: $id');

      final response = await _dio.post('/product-templates/$id/activate');

      print('🟢 ProductTemplateRemoteDataSource: Шаблон товара активирован');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка активации шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<void>> deactivateProductTemplate(int id) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Деактивируем шаблон товара: $id');

      final response = await _dio.post('/product-templates/$id/deactivate');

      print('🟢 ProductTemplateRemoteDataSource: Шаблон товара деактивирован');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка деактивации шаблона: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  @override
  Future<ApiResponse<List<String>>> getAvailableUnits() async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Получаем доступные единицы измерения');

      final response = await _dio.get('/product-templates/units');

      print('🟢 ProductTemplateRemoteDataSource: Получены единицы измерения');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List).cast<String>(),
      );
    } on DioException catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка получения единиц: ${e.response?.statusCode} - ${e.message}');
      _handleDioException(e);
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Неожиданная ошибка: $e');
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
      throw Exception('Шаблон товара не найден');
    } else if (e.response?.statusCode == 422) {
      throw Exception('Ошибка валидации: ${e.response?.data['message'] ?? e.message}');
    } else if (e.response?.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка сети: ${e.message}');
    }
  }
  
  @override
  Future<List<TemplateAttributeModel>> getTemplateAttributes(int templateId) async {
    try {
      print('🔵 Загружаем атрибуты шаблона $templateId');
      final response = await _dio.get('/product-templates/$templateId/attributes');
      
      print('🔵 Ответ атрибутов шаблона: ${response.data}');
      
      // API возвращает список атрибутов
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data as Map<String, dynamic>)['data'] ?? [];
      
      print('🔵 Количество атрибутов: ${data.length}');
      
      final attributes = data.map((json) {
        final jsonMap = json as Map<String, dynamic>;
        print('🔵 Парсим атрибут: $jsonMap');
        
        final attribute = TemplateAttributeModel.fromJson(jsonMap);
        print('🔵 Атрибут ${attribute.name} (${attribute.type}): selectOptions=${attribute.selectOptions}, value=${attribute.value}, options=${attribute.options}');
        
        return attribute;
      }).toList();
      
      return attributes;
    } on DioException catch (e) {
      print('🔴 Ошибка загрузки атрибутов шаблона: ${e.message}');
      // Возвращаем пустой список если API не работает
      return [];
    }
  }
}

/// Provider для ProductTemplateRemoteDataSource
@riverpod
ProductTemplateRemoteDataSource productTemplateRemoteDataSource(
  ProductTemplateRemoteDataSourceRef ref,
) {
  final dio = ref.watch(dioClientProvider);
  return ProductTemplateRemoteDataSourceImpl(dio);
}
